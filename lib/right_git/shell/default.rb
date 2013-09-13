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
    def execute(cmd, options = {})
      options = {
        :directory        => nil,
        :logger           => nil,
        :outstream        => STDOUT,
        :raise_on_failure => true,
        :set_env_vars     => nil,
        :clear_env_vars   => nil,
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

      # configure and invoke.
      configure_executioner(executioner, options).call

      return exitstatus
    end

    # Implements output_for interface.
    def output_for(cmd, options = {})
      output = StringIO.new
      execute(cmd, options.merge(:outstream => output))
      output.string
    end

    # Encapsulates the given executioner with child-process-modifying behavior
    # based on options. Builds the executioner as a series of callbacks.
    #
    # @param [Proc] executioner to configure
    # @param [Hash] options for execution
    #
    # @return [Proc] configured executioner
    def configure_executioner(executioner, options)
      # set specific environment variables, if requested.
      sev = options[:set_env_vars]
      if (sev && !sev.empty?)
        executioner = lambda do |e|
          lambda { set_env_vars(sev) { e.call } }
        end.call(executioner)
      end

      # clear specific environment variables, if requested.
      cev = options[:clear_env_vars]
      if (cev && !cev.empty?)
        executioner = lambda do |e|
          lambda { clear_env_vars(cev) { e.call } }
        end.call(executioner)
      end

      # working directory.
      if directory = options[:directory]
        executioner = lambda do |e, d|
          lambda { ::Dir.chdir(d) { e.call } }
        end.call(executioner, directory)
      end
      executioner
    end

    # Sets the given list of environment variables while
    # executing the given block.
    #
    # === Parameters
    # @param [Hash] variables to set
    #
    # === Yield
    # @yield [] called with environment set
    #
    # === Return
    # @return [TrueClass] always true
    def set_env_vars(variables)
      save_vars = {}
      variables.each { |k, v| save_vars[k] = ENV[k]; ENV[k] = v }
      begin
        yield
      ensure
        variables.each_key { |k| ENV[k] = save_vars[k] }
      end
      true
    end

    # Clears (set-to-nil) the given list of environment variables while
    # executing the given block.
    #
    # @param [Array] names of variables to clear
    #
    # @yield [] called with environment cleared
    #
    # @return [TrueClass] always true
    def clear_env_vars(names, &block)
      save_vars = {}
      names.each { |k| save_vars[k] = ENV[k]; ENV[k] = nil }
      begin
        yield
      ensure
        names.each { |k| ENV[k] = save_vars[k] }
      end
      true
    end

  end # Default
end # RightGit::Shell
