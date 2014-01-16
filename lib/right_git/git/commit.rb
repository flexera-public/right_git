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

  # A commit within a Git repository.
  class Commit
    include ::RightGit::Git::BelongsToRepository

    COMMIT_INFO = /^([0-9A-Fa-f]+) ([0-9]+) (.*)$/

    COMMIT_SHA1_REGEX = /^[0-9a-fA-F]{40}$/

    class CommitError < GitError; end

    # @param [Repository] repo hosting commit
    # @param [String] line of git output describing commit
    def initialize(repo, line)
      @repo = repo
      unless match = COMMIT_INFO.match(line)
        raise CommitError, "Unrecognized commit summary: #{line.inspect}"
      end
      @info = [ match[1], Integer(match[2]), match[3] ]
    end

    # Provide a String representation of this commit (specifically, its commit hash).
    def to_s
      hash
    end

    # Provide a programmer-friendly representation of this branch.
    def inspect
      '#<%s:%s>' % [self.class.name, hash]
    end

    # The commit hash. This overrides String#hash on purpose
    #
    # @return [String] hash of commit (may be abbreviated)
    def hash
      @info[0]
    end

    # @return [Time] time of commit
    def timestamp
      ::Time.at(@info[1])
    end

    # @return [String] author of commit
    def author
      @info[2]
    end

    # @return [TrueClass|FalseClass] true if the given revision is a (fully qualified, not abbreviated) commit SHA
    def self.sha?(revision)
      !!COMMIT_SHA1_REGEX.match(revision)
    end

  end # Commit
end # RightGit
