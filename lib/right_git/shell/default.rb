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
require 'stringio'
require 'singleton'

module RightGit::Shell

  # Default shell singleton implementation.
  class Default
    include ::RightGit::Shell::Interface
    include ::RightSupport::Ruby::EasySingleton

    # Delegates to the RightGit class logger.
    def default_logger
      ::RightGit::Git::Repository.logger
    end

    # Implements execute interface.
    def execute(cmd, options = {})
      options = {
        :directory        => nil,
        :outstream        => nil,
        :raise_on_failure => true,
        :set_env_vars     => nil,
        :clear_env_vars   => nil,
        :logger           => default_logger,
        :timeout          => nil,
      }.merge(options)
      outstream = options[:outstream]

      logger = options[:logger]

      # build initial popener.
      exitstatus = nil
      popener = lambda do |output|
        output.sync = true
        loop do
          # note stdout remains selectable after process dies.
          if (::IO.select([output], nil, nil, 0.1) rescue nil)
            if data = output.gets
              if outstream
                outstream << data
              else
                data = data.strip
                logger.info(data) unless data.empty?
              end
            else
              break
            end
          end
        end
      end

      # timeout optionally wraps popener. the timeout must happen inside of the
      # IO.popen block or else it has no good effect.
      if timeout = options[:timeout]
        popener = lambda do |p|
          lambda do |o|
            ::Timeout.timeout(timeout) { p.call(o) }
          end
        end.call(popener)
      end

      # build initial executioner in terms of popener.
      executioner = lambda do
        logger.info("+ #{cmd}")
        error_msg = nil
        ::IO.popen("#{cmd} 2>&1", 'r') do |output|
          begin
            popener.call(output)
          rescue ::EOFError
            # done
          rescue ::Timeout::Error
            # kill still-running process or else popen's ensure will hang.
            ::Process.kill('KILL', output.pid)

            # intentionally not reading last data as that could still block
            # due to a child of created process inheriting stdout.
            error_msg = "Execution timed out after #{options[:timeout]} seconds."
          end
        end

        # note that a killed process may exit 0 under Windows.
        exitstatus = $?.exitstatus
        if 0 == exitstatus && error_msg
          exitstatus = 1
        end
        if (exitstatus != 0 && options[:raise_on_failure])
          error_msg ||= "Execution failed with exitstatus #{exitstatus}"
          raise ShellError, error_msg
        end
      end

      # configure executioner (by options) and then invoke executioner.
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
      variables.each do |k, v|
        k = k.to_s
        save_vars[k] = ENV[k]
        ENV[k] = v.nil? ? v : v.to_s
      end
      begin
        yield
      ensure
        variables.each_key do |k|
          k = k.to_s
          ENV[k] = save_vars[k]
        end
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
      names.each do |k|
        k = k.to_s
        save_vars[k] = ENV[k]
        ENV[k] = nil
      end
      begin
        yield
      ensure
        names.each do |k|
          k = k.to_s
          ENV[k] = save_vars[k]
        end
      end
      true
    end

  end # Default
end # RightGit::Shell
