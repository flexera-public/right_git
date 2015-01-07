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

describe RightGit::Git::BranchCollection do

  def make_branch(name, is_remote)
    line = "  #{is_remote ? 'remotes/origin/' : ''}#{name}\n"
    ::RightGit::Git::Branch.new(repo, line)
  end

  let(:repo)     { flexmock('repo') }
  let(:revision) { 'master' }

  let(:branch_list) do
    [
      make_branch('master',   false),
      make_branch('branch_a', false),
      make_branch('branch_b', false),
      make_branch('master',   true),
      make_branch('branch_a', true),
      make_branch('branch_c', true),
    ]
  end
  let(:local_branches) do
    result = []
    branch_list.reject { |branch| branch.remote? }.each do |branch|
      result << branch.fullname
    end
    result
  end
  let(:remote_branches) do
    result = []
    branch_list.select { |branch| branch.remote? }.each do |branch|
      result << branch.fullname
    end
    result
  end

  subject { described_class.new(repo) }

  context 'with no branches' do
    let(:branch_output) { "* (no branch)\n" }

    before(:each) do
      # The branch collection always enumerates all branches when it's constructed
      repo.
        should_receive(:git_output).
        with(['branch', '-a']).
        and_return(branch_output).once.ordered
    end

    context '#new' do
      it 'should enumerate nothing' do
        subject.size.should == 0
      end
    end
  end

  context 'with normal branch listing' do
    let(:branch_output) { "  master\n  branch_a\n  branch_b\n  origin/master\n  origin/branch_a\n  origin/branch_c\n" }

    before(:each) do
      # The branch collection always enumerates all branches when it's constructed
      repo.
        should_receive(:git_output).
        with(['branch', '-a']).
        and_return(branch_output).once.ordered
    end

    context '#new' do
      it 'should enumerate all local and remote branches' do
        subject.size.should == 6
      end
    end

    context '#local' do
      it 'should return local branches only' do
        actual = subject.local
        actual.should be_a_kind_of(described_class)
        actual_branches = []
        actual.each { |branch| actual_branches << branch.fullname }
        actual_branches.should == local_branches
      end
    end

    context '#remote' do
      it 'should return remote branches only' do
        actual = subject.remote
        actual.should be_a_kind_of(described_class)
        actual_branches = []
        actual.each { |branch| actual_branches << branch.fullname }
        actual_branches.should == remote_branches
      end
    end

    context '#merged' do
      let(:merged_branches) { ["origin/#{revision}", 'origin/branch_a'] }
      let(:merged_branch_output) do
        merged_branches.map { |fullname| "  #{fullname}"}.join("\n") + "\n"
      end

      it 'should return merged-to-revision collection' do
        repo.
          should_receive(:git_output).
          with(['branch', '-a', '--merged', revision]).
          and_return(merged_branch_output).
          once
        actual = subject.merged(revision)
        actual.should be_a_kind_of(described_class)
        actual_branches = []
        actual.each { |branch| actual_branches << branch.fullname }
        actual_branches.should == merged_branches
      end
    end
  end

  context 'with detached HEAD' do
    let(:branch_output) { "* (detached from v1.0)\n  master\n  remotes/origin/HEAD -> origin/master" }

    before(:each) do
      # The branch collection always enumerates all branches when it's constructed
      repo.
        should_receive(:git_output).
        with(['branch', '-a']).
        and_return(branch_output).once.ordered
    end

    context '#new' do
      it 'should enumerate branches but ignore detached HEAD' do
        subject.size.should == 2
      end
    end
  end

end # RightGit::BranchCollection
