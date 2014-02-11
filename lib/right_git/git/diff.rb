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
  class Diff
    include ::RightGit::Git::BelongsToRepository

    attr_reader :refs

    # Create a new Diff. Do not fetch any data; all git commands are lazy-evaluated.
    # @param [RightGit::Git::Repository] repo
    # @param [String] refs one or two commit refs; if two, should be separated by a range operator such as "..."
    def initialize(repo, refs)
      @repo = repo
      @refs = refs
    end

    # Gather some information about the files and lines changed in this diff.
    # @return [Hash] map of filenames to subhashes with:inserted and :deleted counts
    #
    # @example Show stats for a small diff
    #   my_diff.stats # => {'lib/foo/bar.rb' => {:inserted => 5, :deleted => 12}}
    def stats
      @stats ||= compute_stats
    end

    private

    # @return [Hash] map of relative pathnames to subhashes with :inserted and :deleted counts
    def compute_stats
      git_args = [
        'diff',
        refs,
        '--numstat'
      ]

      line = nil

      @repo.git_output(git_args).lines.inject({}) do |h, l|
        line = l.strip
        inserted, deleted, path = line.split(/\s+/, 3)
        if inserted !~ /^[+-]/ && deleted !~ /^[+-]/
          h[path] = {:inserted => Integer(inserted), :deleted => Integer(deleted)}
        end
        h
      end
    rescue ArgumentError => e
      raise ArgumentError, "Cannot parse 'git diff #{refs}' output '#{line}': #{e.message}"
    end
  end
end