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

require 'tmpdir'

module RightGit::Git
  class RepositorySpec
    GIT_ERROR = GitError
    TEMP_DIR  = ::File.join(::Dir.tmpdir, 'right_git-repository-3b5e5cd0495e6af9942206efa2626c6e')
    REPO_NAME = 'bar'
    REPO_URL  = "git@github.com:foo/#{REPO_NAME}.git"
    REPO_DIR  = ::File.join(TEMP_DIR, REPO_NAME)
  end
end

describe RightGit::Git::Repository do
  let(:error_class)  { ::RightGit::Git::RepositorySpec::GIT_ERROR }
  let(:shell)        { flexmock('shell') }
  let(:logger)       { flexmock('logger') }
  let(:repo_url)     { ::RightGit::Git::RepositorySpec::REPO_URL }
  let(:repo_name)    { ::RightGit::Git::RepositorySpec::REPO_NAME }
  let(:repo_dir)     { ::RightGit::Git::RepositorySpec::REPO_DIR }
  let(:temp_dir)     { ::RightGit::Git::RepositorySpec::TEMP_DIR }
  let(:vet_error)    { 'Git exited zero but an error was detected in output.' }
  let(:happy_output) do
<<EOF
Doesn't really matter so long as
nothing matches the sad pattern.
EOF
  end
  let(:sad_output) do
<<EOF
As msysgit on Windows...
ERROR: Even though I know it is wrong,
fatal: I appear to succeed by exiting zero while printing errors to STDERR.
EOF
  end

  let(:repo_options) { { :logger => logger, :shell => shell } }

  let(:shell_execute_options) do
    {
      :clear_env_vars => ['GIT_DIR', 'GIT_INDEX_FILE', 'GIT_WORK_TREE'],
      :logger => logger,
      :directory => repo_dir
    }
  end

  subject { described_class.new(repo_dir, repo_options) }

  before(:each) do
    ::FileUtils.rm_rf(repo_dir) if ::File.directory?(repo_dir)
    ::FileUtils.mkdir_p(repo_dir)
    # sanity checks to ensure tests are not using actual git.
    flexmock(::RightGit::Shell::Default).
      should_receive(:execute).
      and_raise(::NotImplementedError).
      never
    flexmock(::RightGit::Shell::Default).
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
              "git clone -- #{repo_url} #{repo_dir}",
              shell_execute_options.merge(:directory => base_dir)).
            and_return do
              ::FileUtils.mkdir_p(::File.join(repo_dir, '.git'))
              happy_output
            end.
            once
          logger.
            should_receive(:info).
            with(happy_output.strip).
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
              "git clone -- #{repo_url} #{repo_dir}",
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
          }.to raise_error(error_class, vet_error)
        end
      end
    end

    before(:each) do
      ::FileUtils.rm_rf(repo_dir) if ::File.directory?(repo_dir)
    end

    [
      [
        ::RightGit::Git::RepositorySpec::TEMP_DIR,
        ::RightGit::Git::RepositorySpec::REPO_NAME
      ],
      [::Dir.pwd, ::RightGit::Git::RepositorySpec::REPO_DIR]
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
          with(happy_output.strip).
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
          to raise_error(error_class, vet_error)
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
          with(happy_output.strip).
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
          to raise_error(error_class, vet_error)
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

  context '#branch_for' do
    let(:branch_name) { 'z_branch' }

    it 'should make branch' do
      actual = subject.branch_for(branch_name)
      actual.should == ::RightGit::Git::Branch.new(subject, branch_name)
    end
  end # branch_for

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
        branches.should be_a_kind_of(::RightGit::Git::BranchCollection)
        branches.empty?.should == expected_branches.empty?
        branches.size.should == expected_branches.size
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
            ::RightGit::Git::Branch::BranchError,
            "Unrecognized branch info: #{sad_output.lines.first.inspect}")
      end
    end

    [
      [
        { :all => false },
        [],
        { 'master' => nil, 'v1.0' => nil, 'v2.0' => nil }],
      [
        {},
        ['-a'],
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

    context 'when pointing to no branch' do
      let(:branches_options)  { { :all => false } }
      let(:git_branch_args)   { [] }
      let(:expected_branches) { [] }
      let(:git_branch_output) do
<<EOF
* (no branch)
EOF
      end
      it_should_behave_like 'git branch'
    end
  end # branches

  context '#tag_for' do
    let(:tag_name) { 'z_tag' }

    it 'should make tag' do
      actual = subject.tag_for(tag_name)
      actual.should == ::RightGit::Git::Tag.new(subject, tag_name)
    end
  end # tag_for

  context '#tags' do
    let(:tag_list) { ['tag_a', 'tag_b', 'tag_c'] }

    it 'should query tags' do
      shell.
        should_receive(:output_for).
        with('git tag', shell_execute_options).
        and_return(tag_list.join("\n") + "\n").
        once
      actual = subject.tags.map(&:name).should == tag_list
    end
  end # tags

  context '#log' do
    shared_examples_for 'git log' do
      it 'should query log' do
        shell.
          should_receive(:output_for).
          with((['git', 'log'] + log_args).join(' '), shell_execute_options).
          and_return(log_output).
          once
        actual = subject.log(revision, log_options)
        actual.should_not be_empty
        actual.first.should be_a_kind_of(::RightGit::Git::Commit)
        actual_commits = actual.map do |commit|
          {
            :hash      => commit.hash,
            :timestamp => commit.timestamp.to_i,
            :author    => commit.author
          }
        end
        actual_commits.should == expected_commits
      end
    end

    context 'with abbreviated hashes' do
      let(:expected_commits) do
        [
          { :hash => '0123456', :timestamp => 1378318888, :author => 'foo@bar.com' },
          { :hash => '789abcd', :timestamp => 1378317777, :author => 'baz@bar.com' },
          { :hash => 'ef01234', :timestamp => 1378316666, :author => 'foo@bar.com' }
        ]
      end
      let(:log_output) do
        expected_commits.inject([]) do |result, data|
          result << "#{data[:hash]} #{data[:timestamp]} #{data[:author]}"
          result
        end.join("\n") + "\n"
      end

      [
        [nil, {}, ['-n1000', '--format="%h %at %aE"']],
        [
          'master',
          { :tail => 3, :no_merges => true },
          ['-n3', '--format="%h %at %aE"', '--no-merges master']
        ]
      ].each do |params|
        context "params = #{params.inspect[0..31]}..." do
          let(:revision)    { params[0] }
          let(:log_options) { params[1] }
          let(:log_args)    { params[2] }
          it_should_behave_like 'git log'
        end
      end
    end # with abbreviated hashes

    context 'with full hashes' do
      let(:expected_commits) do
        [
          { :hash => '0123456789abcdef0123456789abcdef01234567', :timestamp => 1378321111, :author => 'foo@bar.com' },
          { :hash => '89abcdef0123456789abcdef0123456789abcdef', :timestamp => 1378320000, :author => 'baz@bar.com' },
          { :hash => 'abcdef0123456789abcdef0123456789abcdef01', :timestamp => 1378319999, :author => 'foo@bar.com' }
        ]
      end
      let(:log_output) do
        expected_commits.inject([]) do |result, data|
          result << "#{data[:hash]} #{data[:timestamp]} #{data[:author]}"
          result
        end.join("\n") + "\n"
      end

      [
        [
          'foo',
          { :tail => 3, :no_merges => true, :full_hashes => true },
          ['-n3', '--format="%H %at %aE"', '--no-merges foo']
        ]
      ].each do |params|
        context "params = #{params.inspect[0..31]}..." do
          let(:revision)    { params[0] }
          let(:log_options) { params[1] }
          let(:log_args)    { params[2] }
          it_should_behave_like 'git log'
        end
      end
    end # with full hashes
  end # tags

  context '#clean' do
    shared_examples_for 'git clean' do
      it 'should clean' do
        shell.
          should_receive(:execute).
          with(
            (['git', 'clean'] + clean_args).join(' '),
            shell_execute_options).
          and_return(true).
          once
        subject.clean(*clean_args).should be_true
      end
    end # git clean

    [[], ['-X']].each do |params|
      context "params = #{params.inspect}" do
        let(:clean_args) { params }
        it_should_behave_like 'git clean'
      end
    end
  end # clean

  context '#clean_all' do
    shared_examples_for 'git clean all' do
      it 'should clean all' do
        shell.
          should_receive(:execute).
          with(
            (['git', 'clean', '-f'] + clean_all_args).join(' '),
            shell_execute_options).
          and_return(true).
          once
        subject.clean_all(clean_options).should be_true
      end
    end # git clean all

    [
      [{}, []],
      [
        { :directories => true, :gitignored => true, :submodules => true },
        ['-f', '-d', '-x']
      ]
    ].each do |params|
      context "params = #{params.inspect}" do
        let(:clean_options)  { params[0] }
        let(:clean_all_args) { params[1] }
        it_should_behave_like 'git clean all'
      end
    end
  end # clean_all

  context '#checkout_to' do
    shared_examples_for 'git checkout' do
      it 'should checkout' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'checkout'] + checkout_args).join(' '),
            shell_execute_options).
          and_return(happy_output).
          once
        logger.
          should_receive(:info).
          with(happy_output.strip).
          and_return(true).
          once
        subject.checkout_to(revision, checkout_options).should be_true
      end

      it 'should detect errors' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'checkout'] + checkout_args).join(' '),
            shell_execute_options).
          and_return(sad_output).
          once
        logger.
          should_receive(:info).
          with(sad_output.strip).
          and_return(true).
          once
        expect { subject.checkout_to(revision, checkout_options) }.
          to raise_error(error_class, vet_error)
      end
    end # git checkout

    [
      ['foo', {}, ['foo']],
      ['master', { :force => true }, ['master', '--force']]
    ].each do |params|
      context "params = #{params.inspect}" do
        let(:revision)         { params[0] }
        let(:checkout_options) { params[1] }
        let(:checkout_args)    { params[2] }
        it_should_behave_like 'git checkout'
      end
    end
  end # checkout_to

  context '#hard_reset_to' do
    shared_examples_for 'git reset' do
      it 'should reset' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'reset', '--hard'] + reset_args).join(' '),
            shell_execute_options).
          and_return(happy_output).
          once
        logger.
          should_receive(:info).
          with(happy_output.strip).
          and_return(true).
          once
        subject.hard_reset_to(revision).should be_true
      end

      it 'should detect errors' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'reset', '--hard'] + reset_args).join(' '),
            shell_execute_options).
          and_return(sad_output).
          once
        logger.
          should_receive(:info).
          with(sad_output.strip).
          and_return(true).
          once
        expect { subject.hard_reset_to(revision) }.
          to raise_error(error_class, vet_error)
      end
    end # git reset

    [[nil, []], ['master', ['master']]].each do |params|
      context "params = #{params.inspect}" do
        let(:revision)   { params[0] }
        let(:reset_args) { params[1] }
        it_should_behave_like 'git reset'
      end
    end
  end # hard_reset_to

  context '#submodule_paths' do
    shared_examples_for 'git submodule status' do
      it 'should query submodules' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'submodule', 'status'] + submodule_args).join(' '),
            shell_execute_options).
          and_return(submodule_output).
          once
        actual_submodules = subject.submodule_paths(submodule_options)
        actual_submodules.should == expected_submodules
      end

      it 'should detect errors' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'submodule', 'status'] + submodule_args).join(' '),
            shell_execute_options).
          and_return(sad_output).
          once
        expect { subject.submodule_paths(submodule_options) }.
          to raise_error(
            error_class,
            "Unexpected output from submodule status: #{sad_output.lines.first.chomp.inspect}")
      end
    end # git submodule status

    let(:expected_submodules) { ['foo/bar', 'foo/baz'] }
    let(:submodule_output) do
<<EOF
+0123456789abcdef0123456789abcdef01234567 #{expected_submodules[0]} (v1.0.0-12-g1234567)
 89abcdef0123456789abcdef0123456789abcdef #{expected_submodules[1]} (v2.1-3-g89abcde)
EOF
    end

    [[{}, []], [{:recursive => true}, ['--recursive']]].each do |params|
      context "params = #{params.inspect}" do
        let(:submodule_options) { params[0] }
        let(:submodule_args)    { params[1] }
        it_should_behave_like 'git submodule status'
      end
    end
  end # submodule_paths

  context '#update_submodules' do
    shared_examples_for 'git submodule update' do
      it 'should update submodules' do
        shell.
          should_receive(:execute).
          with(
            (['git', 'submodule', 'update', '--init'] + submodule_args).join(' '),
            shell_execute_options).
          and_return(true).
          once
        subject.update_submodules(submodule_options).should be_true
      end
    end # git submodule update

    [[{}, []], [{ :recursive => true }, ['--recursive']]].each do |params|
      context "params = #{params.inspect}" do
        let(:submodule_options) { params[0] }
        let(:submodule_args)    { params[1] }
        it_should_behave_like 'git submodule update'
      end
    end
  end # update_submodules

  context '#sha_for' do
    shared_examples_for 'git show' do
      it 'should query SHA' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'show'] + show_args).join(' '),
            shell_execute_options).
          and_return(show_output).
          once
        actual_revision = subject.sha_for(revision)
        actual_revision.should == expected_revision
      end

      it 'should detect errors' do
        shell.
          should_receive(:output_for).
          with(
            (['git', 'show'] + show_args).join(' '),
            shell_execute_options).
          and_return(sad_output).
          once
        expect { subject.sha_for(revision) }.
          to raise_error(
            error_class,
            'Unable to locate commit in show output.')
      end
    end # git submodule update

    let(:expected_revision) { '0123456789abcdef0123456789abcdef01234567' }
    let(:show_output) do
<<EOF
commit #{expected_revision}
Author: Psy <psy@psy.psy>
Date:   Mon Aug 12 14:28:58 2013 -0700

    Coding Gangnam Style
...
EOF
    end

    [[nil, []], ['master', ['master']]].each do |params|
      context "params = #{params.inspect}" do
        let(:revision)  { params[0] }
        let(:show_args) { params[1] }
        it_should_behave_like 'git show'
      end
    end
  end # update_submodules

end # RightGit::Repository
