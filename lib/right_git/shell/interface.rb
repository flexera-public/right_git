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
require 'right_git/shell'

module RightGit::Shell

  # Interface for a shell intended to work with RightGit.
  module Interface

    # Return a logger object to be used for logging if nothing else is passed in as an option.
    #
    # Must be overridden.
    #
    # @return [Logger]
    def default_logger
      raise NotImplementedError
    end

    # Run the given command and print the output to stdout.
    #
    # Must be overridden.
    #
    # @param [String] cmd the shell command to run
    # @param [Hash] options for execution
    # @option options :directory [String] to use as working directory during
    #  command execution or nil
    # @option options :outstream [IO] output stream to receive STDOUT and
    #  STDERR from command (default = STDOUT)
    # @option options :raise_on_failure [TrueClass|FalseClass] if true, will
    #  raise a RuntimeError if the command does not end successfully (default), false to ignore errors
    # @option options :set_env_vars [Hash] environment variables to set during
    #  execution (default = none set)
    # @option options :clear_env_vars [Hash] environment variables to clear
    #  during execution (default = none cleared but see :clean_bundler_env)
    # @option options :timeout [Numeric] to kill spawned process when time
    #  (in seconds) expires
    # @option options :keep_alive_interval [Numeric] as periodic timer, in
    #  seconds, for emitting output to keep travis ci from killing job or nil
    #  to remain silent (default). note that keep-alives are always written to
    #  the logger even if command output is being captured by :outstream
    # @option options :keep_alive_timeout [Numeric] as overall timeout, in
    #  seconds, for periodically emitting shell output when child process is
    #  silent, which prevents travis ci from killing a silent job, or nil to
    #  remain silent (default). can be combined with :timeout to ensure child
    #  process is kept alive for a maximum amount of time before it will be
    #  abandoned.
    #
    # @return [Integer] exitstatus of the command
    #
    # @raise [ShellError] on failure only if :raise_on_failure is true
    def execute(cmd, options = {})
      raise NotImplementedError
    end

    # Invoke a shell command and return its output as a string, similar to
    # backtick but defaulting to raising exception on failure.
    #
    # Must be overridden.
    #
    # @param [String] cmd command to execute
    # @param [Hash] options for execution (see execute)
    #
    # @raise [ShellError] on failure only if :raise_on_failure is true
    def output_for(cmd, options = {})
      raise NotImplementedError
    end
  end
end
