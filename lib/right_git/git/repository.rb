#
# Copyright (c) 2013 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# ancestor
require 'right_git/git'

# dependencies
require 'right_support'

module RightGit::Git

  # Provides an API for managing a git repository that is suitable for
  # automation. It is assumed that gestures like creating a new repository,
  # branch or tag are manual tasks beyond the scope of automation so those are
  # not covered here. What is provided are APIs for cloning, fetching, listing
  # and grooming git-related objects.
  class Repository
    include RightSupport::Log::Mixin

    COMMIT_SHA1_REGEX = /^commit ([0-9a-fA-F]{40})$/

    SUBMODULE_STATUS_REGEX = /^([+\- ])([0-9a-fA-F]{40}) (.*) (.*)$/

    attr_reader :repo_dir, :shell

    # @param [String] repo_dir for git actions or '.'
    # @param [Hash] options for repository
    # @option options [Object] :shell for git command execution (default = DefaultShell)
    def initialize(repo_dir, options = {})
      options = {
        :shell  => nil,
      }.merge(options)

      if repo_dir && ::File.directory?(repo_dir)
        @repo_dir = ::File.expand_path(repo_dir)
      else
        raise ::ArgumentError.new('A valid repo_dir is required')
      end

      @shell = options[:shell] || ::RightGit::Shell::Default
    end

    # Factory method to clone the repo given by URL to the given destination and
    # return a new Repository object.
    #
    # Note that cloning to the default working directory-relative location is
    # not currently supported.
    #
    # @param [String] repo_url to clone
    # @param [String] destination path where repo is cloned
    # @param [Hash] options for repository
    #
    # @return [Repository] new repository
    def self.clone_to(repo_url, destination, options = {})
      destination = ::File.expand_path(destination)
      git_args = ['clone', '--', repo_url, destination]
      expected_git_dir = ::File.join(destination, '.git')
      if ::File.directory?(expected_git_dir)
        raise ::ArgumentError,
              "Destination is already a git repository: #{destination.inspect}"
      end
      repo = self.new('.', options)
      repo.vet_output(git_args)
      if ::File.directory?(expected_git_dir)
        repo.instance_variable_set(:@repo_dir, destination)
      else
        raise GitError,
              "Failed to clone #{repo_url.inspect} to #{destination.inspect}"
      end
      repo
    end

    # Fetches using the given options, if any.
    #
    # @param [Array] args for fetch
    #
    # @return [TrueClass] always true
    def fetch(*args)
      vet_output(['fetch', args])
      true
    end

    # Fetches branch and tag information from remote origin.
    #
    # @param [Hash] options for fetch all
    # @option options [TrueClass|FalseClass] :prune as true to prune dead branches
    #
    # @return [TrueClass] always true
    def fetch_all(options = {})
      options = { :prune => false }.merge(options)
      git_args = ['--all']
      git_args << '--prune' if options[:prune]
      fetch(git_args)
      fetch('--tags')  # need a separate call for tags or else you don't get all the tags
      true
    end

    # Factory method for a branch object referencing this repository. The branch may be
    # hypothetical (e.g. does not exist yet).
    #
    # @param [String] branch_name for reference
    #
    # @return [Branch] new branch
    def branch_for(branch_name)
      Branch.new(self, branch_name)
    end

    # Generates a list of known (checked-out) branches from the current git
    # directory.
    #
    # @param [Hash] options for branches
    # @option options [Boolean] :all true to include remote branches, else local only (default)
    #
    # @return [Array] list of branches
    def branches(options = {})
      branches = BranchCollection.new(self)

      if options[:all]
        branches
      else
        branches.local
      end
    end

    # Factory method for a tag object referencing this repository.
    #
    # @param [String] tag_name for reference
    #
    # @return [Branch] new branch
    def tag_for(tag_name)
      Tag.new(self, tag_name)
    end

    # Generates a list of known (fetched) tags from the current git directory.
    #
    # @return [Array] list of tags
    def tags
      git_output('tag').lines.map { |line| Tag.new(self, line.strip) }
    end

    # Generates a list of commits using the given 'git log' arguments.
    #
    # @param [String] revision to log or nil
    # @param [Hash] options for log
    # @option options [Integer] :skip as lines of most recent history to skip (Default = include most recent)
    # @option options [Integer] :tail as max history of log
    # @option options [TrueClass|FalseClass] :merges as true to exclude non-merge commits
    # @option options [TrueClass|FalseClass] :no_merges as true to exclude merge commits
    # @option options [TrueClass|FalseClass] :full_hashes as true show full hashes, false for (7-character) abbreviations
    #
    # @return [Array] list of commits
    def log(revision, options = {})
      options = {
        :skip        => nil,
        :tail        => 10_000,
        :merges      => false,
        :no_merges   => false,
        :full_hashes => false,
      }.merge(options)
      skip = options[:skip]
      git_args = [
        'log',
        "-n#{options[:tail]}",
        "--format=\"#{options[:full_hashes] ? Commit::LOG_FORMAT_LONG : Commit::LOG_FORMAT}\""  # double-quotes are Windows friendly
      ]
      git_args << "--skip #{skip}" if skip
      git_args << "--merges" if options[:merges]
      git_args << "--no-merges" if options[:no_merges]
      git_args << revision if revision
      git_output(git_args).lines.map { |line| Commit.new(self, line.strip) }
    end

    # Cleans the current repository of untracked files.
    #
    # @param [Array] args for clean
    #
    # @return [TrueClass] always true
    def clean(*args)
      git_args = ['clean', args]
      spit_output(git_args)
      true
    end

    # Cleans everything and optionally cleans .gitignored files.
    #
    # @param [Hash] options for checkout
    # @option options [TrueClass|FalseClass] :directories as true to clean untracked directories (but not untracked submodules)
    # @option options [TrueClass|FalseClass] :gitignored as true to clean gitignored (untracked) files
    # @option options [TrueClass|FalseClass] :submodules as true to clean untracked submodules (requires force)
    #
    # @return [TrueClass] always true
    def clean_all(options = {})
      options = {
        :directories => false,
        :gitignored  => false,
        :submodules  => false,
      }.merge(options)
      git_args = ['-f']  # force is required or else -n only lists files.
      git_args << '-f' if options[:submodules]  # double-tap -f to kill untracked submodules
      git_args << '-d' if options[:directories]
      git_args << '-x' if options[:gitignored]
      clean(git_args)
      true
    end

    # Checkout.
    #
    # @param [String] revision for checkout
    # @param [Hash] options for checkout
    # @option options [TrueClass|FalseClass] :force as true to force checkout
    #
    # @return [TrueClass] always true
    def checkout_to(revision, options = {})
      options = {
        :force => false
      }.merge(options)
      git_args = ['checkout', revision]
      git_args << '--force' if options[:force]
      vet_output(git_args)
      true
    end

    # Performs a hard reset to the given revision, if given, or else the last
    # checked-out SHA.
    #
    # @param [String] revision as target for hard reset or nil for hard reset to HEAD
    #
    # @return [TrueClass] always true
    def hard_reset_to(revision)
      git_args = ['reset', '--hard']
      git_args << revision if revision
      vet_output(git_args)
      true
    end

    # Queries the recursive list of submodule paths for the current workspace.
    #
    # @param [Hash] options for submodules
    # @option options [TrueClass|FalseClass] :recursive as true to recursively get submodule paths
    #
    # @return [Array] list of submodule paths or empty
    def submodule_paths(options = {})
      options = {
        :recursive => false
      }.merge(options)
      git_args = ['submodule', 'status']
      git_args << '--recursive' if options[:recursive]
      git_output(git_args).lines.map do |line|
        data = line.chomp
        if matched = SUBMODULE_STATUS_REGEX.match(data)
          matched[3]
        else
          raise GitError,
                "Unexpected output from submodule status: #{data.inspect}"
        end
      end
    end

    # Updates submodules for the current workspace.
    #
    # @param [Hash] options for submodules
    # @option options [TrueClass|FalseClass] :recursive as true to recursively update submodules
    #
    # @return [TrueClass] always true
    def update_submodules(options = {})
      options = {
        :recursive => false
      }.merge(options)
      git_args = ['submodule', 'update', '--init']
      git_args << '--recursive' if options[:recursive]
      spit_output(git_args)
      true
    end

    # Determines the SHA referenced by the given revision. Raises on failure.
    #
    # @param [String] revision or nil for current SHA
    #
    # @return [String] SHA for revision
    def sha_for(revision)
      # note that 'git show-ref' produces easier-to-parse output but it matches
      # both local and remote branch to a simple branch name whereas 'git show'
      # matches at-most-one and requires origin/ for remote branches.
      git_args = ['show', revision].compact
      result = nil
      git_output(git_args).lines.each do |line|
        if matched = COMMIT_SHA1_REGEX.match(line.strip)
          result = matched[1]
          break
        end
      end
      unless result
        raise GitError, 'Unable to locate commit in show output.'
      end
      result
    end

    # Executes and returns the output for a git command. Raises on failure.
    #
    # @param [String|Array] args to execute
    #
    # @return [String] output
    def git_output(*args)
      inner_execute(:output_for, args)
    end

    # Prints the output for a git command.  Raises on failure.
    #
    # @param [String|Array] args to execute
    #
    # @return [TrueClass] always true
    def spit_output(*args)
      inner_execute(:execute, args)
    end

    # msysgit on Windows exits zero even when checkout|reset|fetch fails so we
    # need to scan the output for error or fatal messages. it does no harm to do
    # the same on Linux even though the exit code works properly there.
    #
    # @param [String|Array] args to execute
    #
    # @return [TrueClass] always true
    def vet_output(*args)
      last_output = git_output(*args).strip
      logger.info(last_output) unless last_output.empty?
      if last_output.downcase =~ /^(error|fatal):/
        raise GitError, "Git exited zero but an error was detected in output."
      end
      true
    end

    private

    # git defaults to working in the current directory but is sensitive to
    # GIT_ env vars. we prefer the working directory so ensure any GIT_ that
    # override the working directory are cleared.
    CLEAR_GIT_ENV_VARS = ['GIT_DIR', 'GIT_INDEX_FILE', 'GIT_WORK_TREE'].freeze

    def inner_execute(shell_method, git_args)
      shell.send(
        shell_method,
        ['git', git_args].flatten.join(' '),
        :directory => @repo_dir,
        :clear_env_vars => CLEAR_GIT_ENV_VARS)
    end

  end # Repository
end # RightGit
