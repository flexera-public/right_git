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
    # @param [Repository] repo to host branch collection
    # @param [Array] args as subset of branches or empty
    def initialize(repo, *args)
      @repo = repo
      @branches = args
    end

    def to_s
      "#{self.class.name}: #{@branches.inspect}"
    end
    alias inspect to_s

    # Filters on local branches.
    #
    # @return [BranchCollection] local branches
    def local
      local = BranchCollection.new(@repo)
      @branches.each do |branch|
        local << branch unless branch.remote?
      end
      local
    end

    # Filters on remote branches.
    #
    # @return [BranchCollection] remote branches
    def remote
      remote = BranchCollection.new(@repo)
      @branches.each do |branch|
        remote << branch if branch.remote?
      end
      remote
    end

    # Queries and filters on branches reachable from the given revision, if any.
    #
    # @param [String] revision for listing reachable merged branches
    #
    # @return [BranchCollection] merged branches
    def merged(revision)
      git_args = ['branch', '-r', '--merged', revision]
      all_merged = @repo.git_output(git_args).lines.map do |line|
        Branch.new(@repo, line)
      end

      merged = BranchCollection.new(@repo)
      @branches.each do |candidate|
        # For some reason Set#include? does not play nice with our overridden comparison operators
        # for branches, so we need to do this the hard way :(
        merged << candidate if all_merged.detect { |b| candidate == b }
      end
      merged
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

    def method_missing(meth, *args, &block)
      result = @branches.__send__(meth, *args, &block)

      if result.is_a?(::Array)
        BranchCollection.new(@repo, *result)
      else
        result
      end
    end

  end # BranchCollection
end # RightGit
