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

# local
require 'logger'
require 'stringio'

module RightGit::Shell

  # Default shell implementation
  module Default
    extend ::RightGit::Shell::Interface

    module_function

    # Implements execute interface.
    #
    # @param [String] cmd the shell command to run
    # @param [Hash] options for execution
    #
    # @return [Integer] exitstatus of the command
    #
    # @raise [ShellError] on failure only if :raise_on_failure is true
    def execute(cmd, options = {})
      options = {
        :directory        => nil,
        :logger           => nil,
        :outstream        => STDOUT,
        :raise_on_failure => true,
      }.merge(options)

      unless outstream = options[:outstream]
        raise ::ArgumentError.new('outstream is required')
      end
      logger = options[:logger] || default_logger

      # build execution block.
      exitstatus = nil
      executioner = lambda do
        logger.info("+ #{cmd}")
        ::IO.popen("#{cmd} 2>&1", 'r') do |output|
          output.sync = true
          done = false
          while !done
            begin
              outstream << output.readline
            rescue ::EOFError
              done = true
            end
          end
        end
        exitstatus = $?.exitstatus
        if (!$?.success? && options[:raise_on_failure])
          raise ShellError, "Execution failed with exitstatus #{exitstatus}"
        end
      end

      # directory.
      if directory = options[:directory]
        executioner = lambda do |e, d|
          lambda { ::Dir.chdir(d) { e.call } }
        end.call(executioner, directory)
      end

      # invoke.
      executioner.call

      return exitstatus
    end

    # Implements output_for interface.
    #
    # @param [String] cmd command to execute
    # @param [Hash] options for execution
    #
    # @return [String] entire output (stdout) of the command
    #
    # @raise [ShellError] on failure only if :raise_on_failure is true
    def output_for(cmd, options = {})
      output = StringIO.new
      execute(cmd, options.merge(:outstream => output))
      output.string
    end

  end # Default
end # RightGit::Shell
