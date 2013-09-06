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

require 'logger'
require 'stringio'
require 'tmpdir'

describe RightGit::Shell::Default do

  let(:logger)        { flexmock('logger') }
  let(:is_windows)    { !!(RUBY_PLATFORM =~ /mswin|win32|dos|mingw|cygwin/) }
  let(:command_shell) { is_windows ? 'cmd.exe /C' : 'sh -c' }
  let(:outstream)     { flexmock('outstream') }
  let(:message)       { 'hello world' }

  let(:expected_message) do
    message + (is_windows ? " \n" : "\n")
  end

  let(:shell_execute_options) do
    { :logger => logger, :outstream => outstream }
  end

  subject { ::RightGit::Shell::Default }

  context '#default_logger' do
    it 'should have a default logger' do
      subject.default_logger.should be_a_kind_of(::Logger)
    end
  end

  context '#execute' do
    it 'should execute' do
      cmd = "#{command_shell} \"echo #{message}\""
      logger.
        should_receive(:info).
        with("+ #{cmd}").
        and_return(true).
        once
      outstream.
        should_receive(:<<).
        with(expected_message).
        and_return(true).
        once
      subject.execute(cmd, shell_execute_options).should == 0
    end

    it 'should execute in a specified directory' do
      ::Dir.mktmpdir do |temp_dir|
        expected_dir = ::File.expand_path(temp_dir)
        if is_windows
          cmd = "#{command_shell} \"echo %CD%\""
          expected_dir.gsub!('/', "\\")
        else
          cmd = 'pwd'
        end
        logger.
          should_receive(:info).
          with("+ #{cmd}").
          and_return(true).
          once
        outstream.
          should_receive(:<<).
          with(expected_dir + (is_windows ? " \n" : "\n")).
          and_return(true).
          once
        actual = subject.execute(
          cmd, shell_execute_options.merge(:directory => temp_dir))
        actual.should == 0
      end
    end

    it 'should raise on failure by default' do
      cmd = "#{command_shell} \"exit 99\""
      logger.
        should_receive(:info).
        with("+ #{cmd}").
        and_return(true).
        once
      expect { subject.execute(cmd, shell_execute_options) }.
        to raise_error(
          ::RightGit::Shell::ShellError,
          "Execution failed with exitstatus 99")
    end

    it 'should not raise on failure by request' do
      cmd = "#{command_shell} \"exit 99\""
      logger.
        should_receive(:info).
        with("+ #{cmd}").
        and_return(true).
        once
      actual = subject.execute(
        cmd, shell_execute_options.merge(:raise_on_failure => false))
      actual.should == 99
    end
  end # execute

  context '#output_for' do
    it 'should execute and return output' do
      cmd = "#{command_shell} \"echo #{message}\""
      logger.
        should_receive(:info).
        with("+ #{cmd}").
        and_return(true).
        once
      actual_message = subject.output_for(cmd, shell_execute_options)
      actual_message.should == expected_message
    end
  end

end # RightGit::DefaultShell
