require 'test/unit'
require 'mongo'
require 'mongo-fixture'

require_relative '../lib/generator.rb'

class GenerateTest < Test::Unit::TestCase
  # TODO change name of test
  def test_generate_authors
    client = Mongo::Connection.new 'localhost', 27017
    client.drop_database 'test'
    db = client.db('test')

    fixtures = Mongo::Fixture.new(:commits, db)

    # commit collection tests
    commits = db.collection('commits')
    
    assert_equal 5, commits.count, 'there are not 5 total commits'
    assert_equal 3, commits.find({author: 'mike'}).count, 'mike does not have 3 commtis'
    assert_equal 2, commits.find({author: 'bob'}).count, 'bob does noty have 2 commits'

    commit = fixtures.commits.one
    assert commit["author"] == 'mike', 'commit author name should be mike'
    assert commit["paths"].count == 2, 'commit should have 2 paths'
    assert commit["paths"][0] == 'foo/one.rb', 'first path in commit should be foo/one.rb'
    

    gen = Generator.new db

    # author collection tests
    gen.generate :author, {:out => 'authors'}
    authors = db.collection('authors')

    assert_equal 2, authors.count
    assert_equal 1, authors.find({_id: 'mike'}).count, 'mike has paths'
    assert_equal 1, authors.find({_id: 'bob'}).count, 'bob has paths'
    
    mike = authors.find_one({_id: 'mike'})
    assert_equal 3, mike['total_commits']
    assert_not_nil(entry = mike['paths'].find { |p| p['path'] == 'foo/one.rb' }, 'mike has commited foo/one.rb')
    assert_equal 3, entry['path_commits'], 'mike should have commited foo/one.rb three times'
    
    bob = authors.find_one({_id: 'bob'})
    assert_equal 2, bob['total_commits']
    assert_equal 3, bob['paths'].length, 'bob should have 3 paths'

    
    # path collection tests
    gen.generate :path, {:out => 'paths'}
    paths = db.collection('paths')

    assert_equal 4, paths.count
    path_exists = lambda do |id, total_commits|
      assert_equal 1, paths.find({_id: id}).count, "#{id} must exist in paths"
      assert_equal total_commits, paths.find_one({_id: id})['total_commits']
    end
    path_exists.call 'foo/one.rb', 3
    path_exists.call 'foo/two.rb', 2
    path_exists.call 'foo/three.rb', 4
    path_exists.call 'foo/four.rb', 1

    path_has_n_authors = lambda do |id, n, author|
      path = paths.find_one({_id: id})
      assert_not_nil(entry = path['authors'].find { |a| a['author'] == author }, "#{id} should be commtied by #{author}")
      assert_equal n, entry['author_commits'], "#{id} should be commtied #{n} times by #{author}"
    end

    path_has_n_authors.call 'foo/one.rb', 3, 'mike'
    path_has_n_authors.call 'foo/two.rb', 1, 'mike'
    path_has_n_authors.call 'foo/three.rb', 2, 'mike'

    path_has_n_authors.call 'foo/two.rb', 1, 'bob'
    path_has_n_authors.call 'foo/three.rb', 2, 'bob'
    path_has_n_authors.call 'foo/four.rb', 1, 'bob'

    client.drop_database 'test'
    client.close
  end

private
  def get_commit_doc name, *paths
    {author: name, paths: paths, paths_size: paths.length}
  end
end
