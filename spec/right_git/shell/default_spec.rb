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

require File.expand_path('../../../spec_helper', __FILE__)

require 'stringio'
require 'tmpdir'

module RightGit::Shell
  module DefaultSpec
    def self.windows?
      @is_windows ||= !!(RUBY_PLATFORM =~ /mswin|win32|dos|mingw|cygwin/)
    end
  end
end

describe RightGit::Shell::Default do

  let(:is_windows)    { ::RightGit::Shell::DefaultSpec.windows? }
  let(:command_shell) { is_windows ? 'cmd.exe /C' : 'sh -c' }
  let(:outstream)     { flexmock('outstream') }
  let(:message)       { 'hello world' }

  let(:expected_message) do
    message + (is_windows ? " \n" : "\n")
  end

  let(:shell_execute_options) do
    { :outstream => outstream }
  end

  subject { ::RightGit::Shell::Default }

  context '#execute' do
    it 'should execute' do
      cmd = "#{command_shell} \"echo #{message}\""
      outstream.
        should_receive(:<<).
        with(expected_message).
        and_return(true).
        once
      subject.execute(cmd, shell_execute_options).should == 0
    end

    it 'should execute in a specified directory' do
      ::Dir.mktmpdir do |temp_dir|
        # the mac symlinks /tmp to /private/tmp, which throws off tmpdir expectations unless
        # you fully resolve it.
        expected_dir = ::Dir.chdir(temp_dir) { ::File.expand_path(::Dir.pwd) }
        if is_windows
          cmd = "#{command_shell} \"echo %CD%\""
          expected_dir.gsub!('/', "\\")
        else
          cmd = 'pwd'
        end
        expected_output = expected_dir + (is_windows ? " \n" : "\n")

        outstream.
          should_receive(:<<).
          with(expected_output).
          and_return(true).
          once
        actual = subject.execute(
          cmd, shell_execute_options.merge(:directory => temp_dir))
        actual.should == 0
      end
    end

    it 'should raise on failure by default' do
      cmd = "#{command_shell} \"exit 99\""
      expect { subject.execute(cmd, shell_execute_options) }.
        to raise_error(
          ::RightGit::Shell::ShellError,
          "Execution failed with exitstatus 99")
    end

    it 'should not raise on failure by request' do
      cmd = "#{command_shell} \"exit 99\""
      actual = subject.execute(
        cmd, shell_execute_options.merge(:raise_on_failure => false))
      actual.should == 99
    end

    it 'should execute info logging when outstream is nil' do
      cmd = "#{command_shell} \"echo #{message}\""
      subject.execute(cmd, shell_execute_options.merge(:outstream => nil)).should == 0
    end

    it 'has the right to a logger' do
      logger = flexmock('expensive criminal defense logger')
      logger.should_receive(:info)
      cmd = "#{command_shell} \"echo #{message}\""
      subject.execute(cmd, shell_execute_options.merge(:outstream => nil, :logger => logger)).should == 0
    end

    xit 'will be provided with a logger if it cannot afford one' do
      pending 'very amusing'
    end

    unless ::RightGit::Shell::DefaultSpec.windows?
      it 'should keep-alive by request' do
        logger = flexmock('logger')
        logged = []
        logger.should_receive(:info).and_return do |*args|
          logged << args
          true
        end

        # keeps child process alive by inserting dots in logger output when child
        # process is silent for too long. the keep-alive stops the dots before the
        # child finishes, which simulates allowing the process to be killed by
        # travis ci after a reasonable duration.
        cmd = "#{command_shell} \"echo hi; sleep 1; echo there; sleep 1; echo buddy\""
        subject.execute(
          cmd,
          shell_execute_options.merge(
            :outstream => nil,
            :logger => logger,
            :keep_alive_interval => 0.3,
            :keep_alive_timeout  => 1.5)).should == 0
        logged.should == [["+ #{cmd}"], ['hi'], ['.'], ['.'], ['.'], ['there'], ['.'], ['buddy']]
      end
    end
  end # execute

  context '#output_for' do
    it 'should execute and return output' do
      cmd = "#{command_shell} \"echo #{message}\""
      actual_message = subject.output_for(cmd, shell_execute_options)
      actual_message.should == expected_message
    end

    it 'should set environment variables' do
      environment = {
        'RIGHT_GIT_DEFAULT_SPEC_A' => 1,
        :RIGHT_GIT_DEFAULT_SPEC_B => 'b',
        'RIGHT_GIT_DEFAULT_SPEC_C' => nil
      }
      cmd = is_windows ? 'cmd.exe /C set' : 'sh -c printenv'
      begin
        ENV['RIGHT_GIT_DEFAULT_SPEC_A'].should be_nil
        ENV['RIGHT_GIT_DEFAULT_SPEC_B'].should be_nil
        ENV['RIGHT_GIT_DEFAULT_SPEC_C'].should be_nil
        ENV['RIGHT_GIT_DEFAULT_SPEC_C'] = 'bad'
        actual = subject.output_for(cmd, shell_execute_options.merge(:set_env_vars => environment))
        actual_lines = actual.lines.map { |l| l.strip }.sort
        ENV['RIGHT_GIT_DEFAULT_SPEC_A'].should be_nil
        ENV['RIGHT_GIT_DEFAULT_SPEC_B'].should be_nil
        ENV['RIGHT_GIT_DEFAULT_SPEC_C'].should == 'bad'
      ensure
        ENV['RIGHT_GIT_DEFAULT_SPEC_C'] = nil
      end
      actual_lines.should include "RIGHT_GIT_DEFAULT_SPEC_A=1"
      actual_lines.should include "RIGHT_GIT_DEFAULT_SPEC_B=b"
      actual_lines.should_not include "RIGHT_GIT_DEFAULT_SPEC_C=bad"
    end

    it 'should clear environment variables' do
      names = ['RIGHT_GIT_DEFAULT_SPEC_B', :RIGHT_GIT_DEFAULT_SPEC_C]
      cmd = is_windows ? 'cmd.exe /C set' : 'sh -c printenv'
      begin
        ENV['RIGHT_GIT_DEFAULT_SPEC_A'] = 'good'
        ENV['RIGHT_GIT_DEFAULT_SPEC_B'] = 'bad'
        ENV['RIGHT_GIT_DEFAULT_SPEC_C'] = 'ugly'
        actual = subject.output_for(cmd, shell_execute_options.merge(:clear_env_vars => names))
        actual_lines = actual.lines.map { |l| l.strip }.sort
        ENV['RIGHT_GIT_DEFAULT_SPEC_A'].should == 'good'
        ENV['RIGHT_GIT_DEFAULT_SPEC_B'].should == 'bad'
        ENV['RIGHT_GIT_DEFAULT_SPEC_C'].should == 'ugly'
      ensure
        ENV['RIGHT_GIT_DEFAULT_SPEC_A'] = nil
        ENV['RIGHT_GIT_DEFAULT_SPEC_B'] = nil
        ENV['RIGHT_GIT_DEFAULT_SPEC_C'] = nil
      end
      actual_lines.should include "RIGHT_GIT_DEFAULT_SPEC_A=good"
      actual_lines.should_not include "RIGHT_GIT_DEFAULT_SPEC_B=bad"
      actual_lines.should_not include "RIGHT_GIT_DEFAULT_SPEC_C=ugly"
    end

    unless ::RightGit::Shell::DefaultSpec.windows?
      it 'should keep-alive by request' do
        logger = flexmock('logger')
        logged = []
        logger.should_receive(:info).and_return do |*args|
          logged << args
          true
        end

        # dots appear in the log but not in the captured output.
        cmd = "#{command_shell} \"echo hi; sleep 1; echo there; sleep 1; echo buddy\""
        actual_message = subject.output_for(
          cmd,
          shell_execute_options.merge(
            :logger => logger,
            :keep_alive_interval => 0.3,
            :keep_alive_timeout  => 1.5))
        actual_message.should == "hi\nthere\nbuddy\n"
        logged.should == [["+ #{cmd}"], ['.'], ['.'], ['.'], ['.']]
      end
    end
  end

end # RightGit::DefaultShell
