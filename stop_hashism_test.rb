require 'minitest/autorun'

require_relative 'stop_hashism.rb'

describe GitCommitData do
  before do
    @short_commit = <<~GITCOMMIT
      tree f570057985ff13a02140d4532892e3178bdce43b
      author A Name <a.email@mail.me> 1649669622 +0200
      committer Another Name <other.mail@mail.mw> 1649669623 +0200
      
      initial commit
      ehy!
    GITCOMMIT

    @long_commit = <<~GITCOMMIT
      tree f570057985ff13a02140d4532892e3178bdce43b
      parent 943cc039d5355c37f32b5b7783017614f1ae725a
      author A Name <a.email@mail.me> 2649669622 +0200
      committer Another Name <other.mail@mail.mw> 2649669623 +0200
      
      ★★★★★★★★★★★
      Did many things
      like writing "author" and "committer" in commit messages
      ★★★★★★★★★★★★
    GITCOMMIT
  end

  describe '#initialize' do
    it 'creates template for initial commits' do
      commit = @short_commit

      data = GitCommitData.new(commit)
      _(data.template).must_equal <<~TMPL
        tree f570057985ff13a02140d4532892e3178bdce43b
        author A Name <a.email@mail.me> %{author_timestamp} +0200
        committer Another Name <other.mail@mail.mw> %{committer_timestamp} +0200
        
        initial commit
        ehy!
      TMPL
    end

    it 'also creates template for later commits' do
      commit = @long_commit

      data = GitCommitData.new(commit)
      _(data.template).must_equal <<~TMPL
        tree f570057985ff13a02140d4532892e3178bdce43b
        parent 943cc039d5355c37f32b5b7783017614f1ae725a
        author A Name <a.email@mail.me> %{author_timestamp} +0200
        committer Another Name <other.mail@mail.mw> %{committer_timestamp} +0200
        
        ★★★★★★★★★★★
        Did many things
        like writing "author" and "committer" in commit messages
        ★★★★★★★★★★★★
      TMPL
    end
  end

  describe '#original_timestamps' do
    it '\'parses\' the timestamp fields' do
      commit = @short_commit

      data = GitCommitData.new(commit)
      _(data.author_timestamp).must_equal 1649669622
      _(data.committer_timestamp).must_equal 1649669623

      commit = @long_commit

      data = GitCommitData.new(commit)
      _(data.author_timestamp).must_equal 2649669622
      _(data.committer_timestamp).must_equal 2649669623
    end
  end
end
