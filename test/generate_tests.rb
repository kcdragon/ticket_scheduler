require 'test/unit'
require 'mongo'

require_relative '../lib/generate_authors_collection.rb'

class GenerateTest < Test::Unit::TestCase
  def test_generate_authors
    client = Mongo::Connection.new 'localhost', 27017
    client.drop_database 'test'

    db = client.db('test')
    c1 = db['commits'].insert get_commit_doc('mike', 'foo/one.rb', 'foo/two.rb')
    c2 = db['commits'].insert get_commit_doc('mike', 'foo/one.rb', 'foo/three.rb')
    c3 = db['commits'].insert get_commit_doc('mike', 'foo/one.rb', 'foo/three.rb')
    c4 = db['commits'].insert get_commit_doc('bob', 'foo/two.rb', 'foo/three.rb')
    c5 = db['commits'].insert get_commit_doc('bob', 'foo/three.rb', 'foo/four.rb')

    commits = db.collection('commits')
    
    assert_equal 5, commits.count, 'there are not 5 total commits'
    assert_equal 3, commits.find({author: 'mike'}).count, 'mike does not have 3 commtis'
    assert_equal 2, commits.find({author: 'bob'}).count, 'bob does noty have 2 commits'

    commit = commits.find_one({_id: c1})
    assert commit["author"] == 'mike', 'commit author name should be mike'
    assert commit["paths"].count == 2, 'commit should have 2 paths'
    assert commit["paths"][0] == 'foo/one.rb', 'first path in commit should be foo/one.rb'
    
    gen = GenerateAuthorsCollection.new db
    gen.generate_paths({:out => 'authors'})
    authors = db.collection('authors')

    assert_equal 2, authors.count
    assert_equal 1, authors.find({_id: 'mike'}).count, 'mike has paths'
    assert_equal 1, authors.find({_id: 'bob'}).count, 'bob has paths'
    
    mike = authors.find_one({_id: 'mike'})
    assert_not_nil(entry = mike['value']['paths'].find { |p| p['path'] == 'foo/one.rb' }, 'mike has commtied foo/one.rb')
    assert_equal 3, entry['path_commits'], 'mike should have commited foo/one.rb three times'
    
    bob = authors.find_one({_id: 'bob'})
    assert_equal 3, bob['value']['paths'].length, 'bob should have 3 paths'

    client.drop_database 'test'
    client.close
  end

private
  def get_commit_doc name, *paths
    {author: name, paths: paths, paths_size: paths.length}
  end
end
