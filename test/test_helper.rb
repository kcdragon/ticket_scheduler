require_relative '../lib/models/commit'

class TestHelper
  def self.insert_commits
    commits = []
    commits << Commit.create(get_commit_doc('mike', 'foo/one.rb', 'foo/two.rb'))
    commits << Commit.create(get_commit_doc('mike', 'foo/one.rb', 'foo/three.rb'))
    commits << Commit.create(get_commit_doc('mike', 'foo/one.rb', 'foo/three.rb'))
    commits << Commit.create(get_commit_doc('bob', 'foo/two.rb', 'foo/three.rb'))
    commits << Commit.create(get_commit_doc('bob', 'foo/three.rb', 'foo/four.rb'))
    commits
  end
private
  def self.get_commit_doc name, *paths
    {author: name, paths: paths, paths_size: paths.length}
  end
end
