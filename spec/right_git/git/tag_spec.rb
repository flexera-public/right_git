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

describe RightGit::Git::Tag do

  let(:repo) { flexmock('repo') }

  subject { described_class.new(repo, branch_line) }

  shared_examples_for 'all tags' do
    it 'should behave like a tag' do
      subject.name.should == tag_name
      subject.repo.should == repo
      subject.should == subject
      (subject <=> subject).should == 0
      subject.inspect.should == "#{described_class.name}: #{tag_name.inspect}"
      subject.to_s.should == subject.inspect
    end

    context 'given a similar tag' do
      let(:other) { described_class.new(repo, tag_name) }

      it 'should be equivalent' do
        subject.should == other
        (subject <=> other).should == 0
      end
    end

    context 'given a different tag' do
      let(:other) { described_class.new(repo, 'hmmm') }

      it 'should differ' do
        subject.should_not == other
        (subject <=> other).should_not == 0
      end
    end
  end

  shared_examples_for 'a tag' do
    it_should_behave_like 'all tags'

    it 'should delete' do
      repo.
        should_receive(:vet_output).
        with("tag -d #{tag_name}").
        and_return(true).
        once
      subject.delete.should be_true
    end
  end

end
