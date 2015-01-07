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

module RightGit::Git

  # A collection of Git branches. Acts a bit like an Array, allowing it to be
  # mapped, sorted and compared as such.
  class BranchCollection
    include ::RightGit::Git::BelongsToRepository

    # Regexp matching (and capturing) the output of 'git symbolic-ref'; used to determine which
    # branch is currently checked out.
    HEAD_REF = %r{^refs/heads/(#{Branch::BRANCH_NAME})$}

    # The output of 'git symbolic-ref' when the HEAD ref is not on any branch.
    NO_HEAD_REF = /^HEAD is not a symbolic ref$/

    # The output of the 'git branch' command when the HEAD ref is not on any
    # branch or in a detached HEAD state (e.g. "* (detached from v1.0)") when
    # pointing to a tag or the repo has no branches ("* (no branch)").
    #
    # This is not useful to RightGit, so we must filter it out of Git's output
    # when we see it.
    NOT_A_BRANCH = /^\* \(.*\)$/

    # Create a new BranchCollection. Don't pass in a branches parameter unless you really know
    # what you're doing; it's intended more for internal use than anything else.
    #
    # @param [Repository] repo to host branch collection
    # @param optional [Array] branches an array of Branch objects, or nil to auto-populate this collection with ALL branches
    def initialize(repo, branches=nil)
      @repo = repo

      if branches
        # Use an arbitrary set of branches that was passed in
        @branches = branches
      else
        @branches = []

        # Initialize ourselves with all branches in the repository
        git_args = ['branch', '-a']
        @repo.git_output(git_args).lines.each do |line|
          line.strip!

          if line =~ NOT_A_BRANCH
            #no-op; ignore this one
          else
            @branches << Branch.new(@repo, line)
          end
        end
      end
    end

    # Provide a String representation of this collection, depicting it as a comma-separated list of
    # branch names.
    def to_s
      @branches.join(',')
    end

    # Provide a programmer-friendly representation of this collection.
    def inspect
      '#<%s:%s>' % [self.class.name, @branches.inspect]
    end

    # Return a Branch object representing whichever branch is currently checked out, IF AND ONLY IF
    # that branch is a member of the collection. If the current branch isn't part of the collection
    # or HEAD refers to something other than a branch, return nil.
    #
    # @return [Branch] the current branch if any, nil otherwise
    def current
      lines = @repo.git_output(['symbolic-ref', 'HEAD'], :raise_on_failure => false).lines

      if lines.size == 1
        line = lines.first.strip
        if (match = HEAD_REF.match(line))
          @branches.detect { |b| b.fullname == match[1] }
        elsif line == NO_HEAD_REF
          nil
        end
      else
        raise GitError, "Unexpected output from 'git symbolic-ref'; need 1 lines, got #{lines.size}"
      end
    end

    # Return another collection that contains only the local branches in this collection.
    #
    # @return [BranchCollection] local branches
    def local
      local = []

      @branches.each do |branch|
        local << branch unless branch.remote?
      end

      BranchCollection.new(@repo, local)
    end

    # Return another collection that contains only the local branches in this collection.
    #
    # @return [BranchCollection] remote branches
    def remote
      remote = []

      @branches.each do |branch|
        remote << branch if branch.remote?
      end

      BranchCollection.new(@repo, remote)
    end

    # Queries and filters on branches reachable from the given revision, if any.
    #
    # @param [String] revision for listing reachable merged branches
    #
    # @return [BranchCollection] merged branches
    def merged(revision)
      # By hand, build a list of all branches known to be merged into master
      git_args = ['branch', '-a', '--merged', revision]
      all_merged = []
      @repo.git_output(git_args).lines.each do |line|
        line.strip!
        all_merged << Branch.new(@repo, line)
      end

      # Filter the contents of this collection according to the big list
      merged = []
      @branches.each do |candidate|
        # For some reason Set#include? does not play nice with our overridden comparison operators
        # for branches, so we need to do this the hard way :(
        merged << candidate if all_merged.detect { |b| candidate == b }
      end

      BranchCollection.new(@repo, merged)
    end

    # Accessor that acts like either a Hash or Array accessor
    def [](argument)
      case argument
      when String
        target = Branch.new(@repo, argument)
        @branches.detect { |b| b == target }
      else
        @branches.__send__(:[], argument)
      end
    end

    # Dispatch to the underlying Array of Branch objects, allowing the branch collection to act a
    # bit like an Array.
    #
    # If the dispatched-to method returns an Array, it is wrapped in another BranchCollection object
    # before returning to the caller. This allows array-like method calls to be chained together
    # without losing the BranchCollection-ness of the underlying object.
    def method_missing(meth, *args, &block)
      result = @branches.__send__(meth, *args, &block)

      if result.is_a?(::Array)
        BranchCollection.new(@repo, result)
      else
        result
      end
    end

    # Polite implementation of #respond_to that honors our #method_missing.
    def respond_to?(meth)
      super || @branches.respond_to?(meth)
    end
  end # BranchCollection
end # RightGit
