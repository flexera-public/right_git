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

  # A tag in a Git repository.
  class Tag
    include ::RightGit::Git::BelongsToRepository

    attr_reader :name

    class TagError < GitError; end

    # @param [Repository] repo hosting tag
    # @param [String] name of tag
    def initialize(repo, name)
      # TEAL FIX: only invalid characters seem to be whitespace and some file
      # system special characters; need to locate a definitive schema for tag
      # names.
      if name.index(/\s|[:\\?*<>\|]/)
        raise TagError, 'name is invalid'
      end
      @repo = repo
      @name = name
    end

    # @return [String] the tag's name
    def to_s
      name
    end

    # @return [String] info about this Ruby object
    def inspect
      "#<#{self.class.name}:#{name.inspect}>"
    end

    # @param [Tag] other
    # @return [TrueClass|FalseClass] true if equivalent
    def ==(other)
      if other.kind_of?(self.class)
        @name == other.name
      else
        false
      end
    end

    # @param [Tag] other
    # @return [Integer] comparison value
    def <=>(other)
      if other.kind_of?(self.class)
        @name <=> other.name
      else
        raise ::ArgumentError, 'Wrong type'
      end
    end

    # Deletes this tag.
    #
    # @return [TrueClass] always true
    def delete
      @repo.vet_output("tag -d #{@name}")
      true
    end

  end # Tag
end # RightGit
