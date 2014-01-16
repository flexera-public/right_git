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

require 'digest/sha1'

describe RightGit::Git::Commit do

  let(:repo) { flexmock('repo') }

  let(:commit_hash)      { '0123456' }
  let(:commit_timestamp) { ::Time.now.to_i }
  let(:commit_author)    { 'foo@bar.com' }
  let(:commit_comment)   { 'i like bees' }

  subject { described_class.new(repo, commit_line) }

  shared_examples_for 'all commits' do
    it 'should behave like a commit' do
      subject.hash.should == commit_hash
      subject.timestamp.should == ::Time.at(commit_timestamp)
      subject.author.should == commit_author
      subject.comment.should == commit_comment
      subject.repo.should == repo
      subject.inspect.should == "#<#{described_class.name}:#{commit_hash}>"
      subject.to_s.should == commit_hash
    end
  end

  context 'when line is valid' do
    let(:commit_line) { "#{commit_hash} #{commit_timestamp} #{commit_author} #{commit_comment}" }
    it_should_behave_like 'all commits'
  end

  context 'when line is invalid' do
    let(:commit_line) { "Some error message" }

    it 'should raise error' do
      expect { subject }.to raise_error(
        described_class::CommitError,
        "Unrecognized commit summary: #{commit_line.inspect}")
    end
  end

  context '.sha?' do
    it 'should be true when given a SHA' do
      described_class.sha?(::Digest::SHA1.hexdigest('meat')).should be_true
    end

    it 'should be false otherwise' do
      described_class.sha?('potatoes').should be_false
    end
  end

end
