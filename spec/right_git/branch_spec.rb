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

require File.expand_path('../../spec_helper', __FILE__)

describe RightGit::Branch do

  let(:repo) { flexmock('repo') }

  subject { described_class.new(repo, branch_line) }

  shared_examples_for 'all branches' do
    it 'should behave like a branch' do
      subject.fullname.should == branch_name
      subject.repo.should == repo
      subject.should == subject
      (subject <=> subject).should == 0
      (subject =~ ::Regexp.compile(::Regexp.escape(branch_name))).should == 0
      subject.inspect.should == "#{described_class.name}: #{branch_name.inspect}"
      subject.to_s.should == subject.inspect
      subject.display(branch_name.length + 1).should == branch_name + ' '
    end

    context 'given a similar branch' do
      let(:other) { described_class.new(repo, branch_line) }

      it 'should be equivalent' do
        subject.should == other
        (subject <=> other).should == 0
      end
    end

    context 'given a different branch' do
      let(:other) { described_class.new(repo, "remotes/origin/hmmm") }

      it 'should differ' do
        subject.should_not == other
        (subject <=> other).should_not == 0
      end
    end
  end

  shared_examples_for 'a local branch' do
    it_should_behave_like 'all branches'

    it 'should be local' do
      subject.should_not be_remote
      subject.name.should == branch_name
    end

    it 'should delete' do
      repo.
        should_receive(:spit_output).
        with("branch -D #{branch_name}").
        and_return(true).
        once
      subject.delete.should be_true
    end
  end

  shared_examples_for 'a remote branch' do
    it_should_behave_like 'all branches'

    let(:simple_name) { branch_name.split('/').last }

    it 'should be remote' do
      subject.should be_remote
      subject.name.should == simple_name
    end

    it 'should delete' do
      repo.
        should_receive(:vet_output).
        with("push origin :#{simple_name}").
        and_return(true).
        once
      subject.delete.should be_true
    end
  end

  context 'when line is invalid' do
    let(:branch_line) { 'Some error message' }

    it 'should raise' do
      expect { subject }.to raise_error(
        described_class::BranchError,
        "Unrecognized branch info: #{branch_line.inspect}")
    end
  end

  context 'when branch is local' do
    let(:branch_name) { 'foo' }

    context 'when line is trivial' do
      let(:branch_line) { branch_name }
      it_should_behave_like 'a local branch'
    end

    context 'when line has a current branch marker' do
      let(:branch_line) { "* #{branch_name}" }
      it_should_behave_like 'a local branch'
    end

    context 'when line is indented with no current branch marker' do
      let(:branch_line) { "  #{branch_name}" }
      it_should_behave_like 'a local branch'
    end

  end

  context 'when branch is remote' do
    let(:branch_name) { 'origin/baz' }

    context 'when line contains an origin' do
      let(:branch_line) { "remotes/#{branch_name}" }
      it_should_behave_like 'a remote branch'
    end

    context 'when line contains an indented remotes reference' do
      let(:branch_line) { "  remotes/#{branch_name}" }
      it_should_behave_like 'a remote branch'
    end

    context 'when line contains an indented remotes reference' do
      let(:branch_line) { "  remotes/#{branch_name}" }
      it_should_behave_like 'a remote branch'
    end
  end

  context 'when branch is a remote HEAD' do
    let(:branch_name) { 'origin/HEAD' }

    context 'when line contains a remote link' do
      let(:branch_line) { "  remotes/#{branch_name} -> origin/master" }
      it_should_behave_like 'a remote branch'
    end
  end

  context 'when branch name is long' do
    let(:branch_name) { 'x' * (2 * described_class::DEFAULT_DISPLAY_WIDTH) }
    let(:branch_line) { branch_name }

    it_should_behave_like 'a local branch'

    it 'should be clipped by display' do
      expected = (
        'x' * (
          described_class::DEFAULT_DISPLAY_WIDTH -
            described_class::ELLIPSIS.length
        )
      ) + described_class::ELLIPSIS
      subject.display.should == expected
    end
  end

end
