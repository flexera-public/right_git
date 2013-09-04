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

require 'tmpdir'

module RightGit
  class RepositorySpec
    TEMP_DIR  = ::File.join(::Dir.tmpdir, 'right_git-repository-3b5e5cd0495e6af9942206efa2626c6e')
    REPO_NAME = 'bar'
    REPO_URL  = "git@github.com:foo/#{REPO_NAME}.git"
    REPO_DIR  = ::File.join(TEMP_DIR, REPO_NAME)
  end
end

describe RightGit::Repository do
  let(:shell)     { flexmock('shell') }
  let(:logger)    { flexmock('logger') }
  let(:repo_url)  { ::RightGit::RepositorySpec::REPO_URL }
  let(:repo_name) { ::RightGit::RepositorySpec::REPO_NAME }
  let(:repo_dir)  { ::RightGit::RepositorySpec::REPO_DIR }
  let(:temp_dir)  { ::RightGit::RepositorySpec::TEMP_DIR }

  let(:vet_error)    { 'git exited zero but an error was detected in output.' }
  let(:happy_output) { 'joy' }
  let(:sad_output) do
<<EOF
As msysgit on Windows...
ERROR: Even though I know it is wrong,
fatal: I appear to succeed by exiting zero while printing errors to STDERR.
EOF
  end

  let(:repo_options) { { :logger => logger, :shell => shell } }

  let(:shell_execute_options) { { :logger => logger, :directory => repo_dir } }

  subject { described_class.new(repo_dir, repo_options) }

  before(:each) do
    ::FileUtils.rm_rf(repo_dir) if ::File.directory?(repo_dir)
    ::FileUtils.mkdir_p(repo_dir)
    # sanity checks to ensure tests are not using actual git.
    flexmock(::RightGit::DefaultShell).
      should_receive(:execute).
      and_raise(::NotImplementedError).
      never
    flexmock(::RightGit::DefaultShell).
      should_receive(:output_for).
      and_raise(::NotImplementedError).
      never
  end

  after(:all) do
    (::FileUtils.rm_rf(temp_dir) rescue nil) if ::File.directory?(temp_dir)
  end

  context '#clone_to' do
    shared_examples_for 'git clone' do
      it 'should clone' do
        ::Dir.chdir(base_dir) do
          shell.
            should_receive(:output_for).
            with(
              "git clone #{repo_url} #{repo_dir}",
              shell_execute_options.merge(:directory => base_dir)).
            and_return do
              ::FileUtils.mkdir_p(::File.join(repo_dir, '.git'))
              happy_output
            end.
            once
          logger.
            should_receive(:info).
            with(happy_output).
            and_return(true).
            once
          repo = described_class.clone_to(repo_url, directory, repo_options)
          repo.should be_a_kind_of(described_class)
          repo.repo_dir.should == repo_dir
          repo.logger.should == logger
          repo.shell.should == shell
        end
      end

      it 'should detect errors' do
        ::Dir.chdir(base_dir) do
          shell.
            should_receive(:output_for).
            with(
              "git clone #{repo_url} #{repo_dir}",
              shell_execute_options.merge(:directory => base_dir)).
            and_return(sad_output).
            once
          logger.
            should_receive(:info).
            with(sad_output.strip).
            and_return(true).
            once
          expect {
            described_class.clone_to(repo_url, directory, repo_options)
          }.to raise_error(described_class::GitError, vet_error)
        end
      end
    end

    before(:each) do
      ::FileUtils.rm_rf(repo_dir) if ::File.directory?(repo_dir)
    end

    [
      [
        ::RightGit::RepositorySpec::TEMP_DIR,
        ::RightGit::RepositorySpec::REPO_NAME
      ],
      [::Dir.pwd, ::RightGit::RepositorySpec::REPO_DIR]
    ].each do |params|
      context "" do
        let(:base_dir)  { params[0] }
        let(:directory) { params[1] }
        it_should_behave_like 'git clone'
      end
    end
  end

  context '#fetch' do
    shared_examples_for 'git fetch' do
      it 'should fetch' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'fetch'] + fetch_args).join(' '),
            shell_execute_options).
          and_return(happy_output).
          once
        logger.
          should_receive(:info).
          with(happy_output).
          and_return(true).
          once
        subject.fetch(*fetch_args).should be_true
      end

      it 'should detect errors' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'fetch'] + fetch_args).join(' '),
            shell_execute_options).
          and_return(sad_output).
          once
        logger.
          should_receive(:info).
          with(sad_output.strip).
          and_return(true).
          once
        expect { subject.fetch(*fetch_args) }.
          to raise_error(described_class::GitError, vet_error)
      end
    end # git fetch

    [
      [],
      ['--all', '--prune']
    ].each do |params|
      context "params = #{params.inspect}" do
        let(:fetch_args) { params }
        it_should_behave_like 'git fetch'
      end
    end
  end # fetch

  context '#fetch_all' do
    shared_examples_for 'git fetch all' do
      it 'should fetch all' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'fetch', '--all'] + git_fetch_all_args).join(' '),
            shell_execute_options).
          and_return(happy_output).
          once
        shell.
          should_receive(:output_for).
          with('git fetch --tags', shell_execute_options).
          and_return(happy_output).
          once
        logger.
          should_receive(:info).
          with(happy_output).
          and_return(true).
          twice
        subject.fetch_all(fetch_all_options).should be_true
      end

      it 'should detect errors' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'fetch', '--all'] + git_fetch_all_args).join(' '),
            shell_execute_options).
          and_return(sad_output).
          once
        logger.
          should_receive(:info).
          with(sad_output.strip).
          and_return(true).
          once
        expect { subject.fetch_all(fetch_all_options) }.
          to raise_error(described_class::GitError, vet_error)
      end
    end # git fetch all

    [
      [{}, []],
      [{ :prune => true }, ['--prune']]
    ].each do |params|
      context "params = #{params.inspect}" do
        let(:fetch_all_options)  { params[0] }
        let(:git_fetch_all_args) { params[1] }
        it_should_behave_like 'git fetch all'
      end
    end
  end # fetch_all

  context '#branches' do
    shared_examples_for 'git branch' do
      it 'should enumerate branches' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'branch'] + git_branch_args).join(' '),
            shell_execute_options).
          and_return(git_branch_output).
          once
        branches = subject.branches(branches_options)
        branches.should be_a_kind_of(::RightGit::BranchCollection)
        branches.should_not be_empty
        actual_branches = []
        branches.each { |branch| actual_branches << branch.fullname }
        actual_branches.sort.should == expected_branches.sort
      end

      it 'should detect errors' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'branch'] + git_branch_args).join(' '),
            shell_execute_options).
          and_return(sad_output).
          once
        expect { subject.branches(branches_options) }.
          to raise_error(
            ::RightGit::Branch::BranchError,
            "Unrecognized branch info #{sad_output.lines.first.inspect}")
      end
    end

    [
      [
        { :all => false },
        [],
        { 'master' => nil, 'v1.0' => nil, 'v2.0' => nil }],
      [
        {},
        ['--all'],
        {
          'master'      => nil,
          'v1.0'        => nil,
          'origin/HEAD' => 'origin/master',
          'origin/v1.0' => nil,
          'origin/v2.0' => nil
        }
      ]
    ].each do |params|
      context "params = #{params.inspect[0..31]}..." do
        let(:branches_options)  { params[0] }
        let(:git_branch_args)   { params[1] }
        let(:expected_branches) { params[2].keys }
        let(:git_branch_output) do
          params[2].inject([]) do |result, (k, v)|
            if v
              line = "  remotes/#{k} -> #{v}"
            else
              line = "#{k == 'master' ? '*' : ' '} #{k.index('/') ? 'remotes/' : ''}#{k}"
            end
            result << line
            result
          end.join("\n") + "\n"
        end
        it_should_behave_like 'git branch'
      end
    end

  end # branches

end # RightGit::Repository
