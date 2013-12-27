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

  # A branch in a Git repository. Has some proxy methods that make it act a bit
  # like a string, whose value is the name of the branch. This allows branches
  # to be sorted, matched against Regexp, and certain other string-y operations.
  class Branch
    BRANCH_NAME     = '[#A-Za-z0-9._\/+-]+'
    BRANCH_INFO     = /^(\* |  )?(#{BRANCH_NAME})( -> #{BRANCH_NAME})?$/
    BRANCH_FULLNAME = /(remotes\/)?(#{BRANCH_NAME})/

    DEFAULT_DISPLAY_WIDTH = 40

    ELLIPSIS = '...'

    class BranchError < GitError; end

    attr_reader :repo, :fullname

    # @param [Repository] repo hosting branch
    # @param [String] line of git output describing branch
    def initialize(repo, line)
      match = BRANCH_INFO.match(line)
      if match && (fullname = match[2])
        match = BRANCH_FULLNAME.match(fullname)
        if match
          @fullname = match[2]
          @remote = !!(match[1] || fullname.index('/'))
          @repo = repo
        else
          raise BranchError, 'Unreachable due to already matching name pattern'
        end
      else
        raise BranchError, "Unrecognized branch info: #{line.inspect}"
      end
    end

    # @return [String] stringized
    def to_s
      "#{self.class.name}: #{@fullname.inspect}"
    end
    alias inspect to_s

    # @param [Regexp] regexp
    # @return [Integer] match offset
    def =~(other)
      @fullname =~ other
    end

    # @param [Branch] other
    # @return [TrueClass|FalseClass] true if equivalent
    def ==(other)
      if other.kind_of?(self.class)
        @fullname == other.fullname
      else
        false
      end
    end

    # @param [Branch] other
    # @return [Integer] comparison value
    def <=>(other)
      if other.kind_of?(self.class)
        @fullname <=> other.fullname
      else
        raise ::ArgumentError, 'Wrong type'
      end
    end

    # @return [TrueClass|FalseClass] true if branch is remote
    def remote?
      @remote
    end

    # @return [String] name of branch sans origin (if any)
    def name
      if remote?
        #remove the initial remote-name in the branch (origin/master --> master)
        bits = @fullname.split('/')
        bits.shift
        bits.join('/')
      else
        @fullname
      end
    end

    # For display in a column of given width.
    #
    # @param [Integer] width for columns
    #
    # @return [String] display string
    def display(width = DEFAULT_DISPLAY_WIDTH)
      if @fullname.length >= width
        (@fullname[0..(width - ELLIPSIS.length - 1)] + ELLIPSIS).ljust(width)
      else
        @fullname.ljust(width)
      end
    end

    # Deletes this (local or remote) branch.
    #
    # @return [TrueClass] always true
    def delete
      if self.remote?
        @repo.vet_output("push origin :#{self.name}")
      else
        @repo.vet_output("branch -D #{@fullname}")
      end
      true
    end

  end # Branch
end # RightGit
