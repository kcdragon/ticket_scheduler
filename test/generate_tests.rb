require 'test/unit'
require 'mongoid'

require_relative 'test_helper'
require_relative '../lib/models/commit'
require_relative '../lib/generator'

class GenerateTest < Test::Unit::TestCase
  def test_generate
    config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/mongoid.yml'
    Mongoid.load!(config_file, :development)
    Mongoid.connect_to('test')
    
    Commit.delete_all
    Author.delete_all
    Path.delete_all
    
    inserted = TestHelper.insert_commits

    # commit collection tests
    commits = Commit
    
    assert_equal 5, commits.count, 'there are not 5 total commits'
    assert_equal 3, commits.where({author: 'mike'}).count, 'mike does not have 3 commtis'
    assert_equal 2, commits.where({author: 'bob'}).count, 'bob does noty have 2 commits'

    commit = inserted[0]
    assert commit.author == 'mike', 'commit author name should be mike'
    assert commit.paths.count == 2, 'commit should have 2 paths'
    assert commit.paths[0] == 'foo/one.rb', 'first path in commit should be foo/one.rb'
    

    gen = Generator.new

    # author collection tests
    gen.generate :author, {:out => 'authors'}

    assert_equal 2, Author.count
    assert_equal 1, Author.where({_id: 'mike'}).count, 'mike has paths'
    assert_equal 1, Author.where({_id: 'bob'}).count, 'bob has paths'
    
    mike = Author.find 'mike'
    assert_equal 3, mike.total_commits
    entry = nil
    mike.paths.each do |p|
      entry = p if p.path == 'foo/one.rb'
    end
    #entry = mike.paths.find { |p| p.path == 'foo/one.rb' } HACK not sure why this won't work and I have to use .each, Mongoid Array must be overrideing find
    assert_not_nil(entry, 'mike has commited foo/one.rb')
    assert_equal 3, entry.path_commits, 'mike should have commited foo/one.rb three times'

    bob = Author.find 'bob'
    assert_equal 2, bob.total_commits
    assert_equal 3, bob.paths.length, 'bob should have 3 paths'
    
    # path collection tests
    gen.generate :path, {:out => 'paths'}

    assert_equal 4, Path.count
    path_exists = lambda do |id, total_commits|
      assert Path.where(_id: id).exists?, "#{id} must exist in paths"
      assert_equal total_commits, Path.find(id).total_commits
    end
    path_exists.call 'foo/one.rb', 3
    path_exists.call 'foo/two.rb', 2
    path_exists.call 'foo/three.rb', 4
    path_exists.call 'foo/four.rb', 1

    path_has_n_authors = lambda do |id, n, author|
      path = Path.find(id)
      entry = nil
      path.authors.each do |a|
        entry = a if a.author == author
      end
      assert_not_nil(entry, "#{id} should be commtied by #{author}")
      assert_equal n, entry['author_commits'], "#{id} should be commtied #{n} times by #{author}"
    end

    path_has_n_authors.call 'foo/one.rb', 3, 'mike'
    path_has_n_authors.call 'foo/two.rb', 1, 'mike'
    path_has_n_authors.call 'foo/three.rb', 2, 'mike'

    path_has_n_authors.call 'foo/two.rb', 1, 'bob'
    path_has_n_authors.call 'foo/three.rb', 2, 'bob'
    path_has_n_authors.call 'foo/four.rb', 1, 'bob'
  end

#private

#  def insert_commits
#    commits = []
#    commits << Commit.create(get_commit_doc('mike', 'foo/one.rb', 'foo/two.rb'))
#    commits << Commit.create(get_commit_doc('mike', 'foo/one.rb', 'foo/three.rb'))
#    commits << Commit.create(get_commit_doc('mike', 'foo/one.rb', 'foo/three.rb'))
#    commits << Commit.create(get_commit_doc('bob', 'foo/two.rb', 'foo/three.rb'))
#    commits << Commit.create(get_commit_doc('bob', 'foo/three.rb', 'foo/four.rb'))
#    commits
#  end
#  def get_commit_doc name, *paths
#    {author: name, paths: paths, paths_size: paths.length}
#  end
end
