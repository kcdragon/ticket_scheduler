require 'test/unit'
require 'mongo'
require 'mongo-fixture'

require_relative '../lib/generator.rb'
require_relative '../lib/metrics.rb'

class MetricTest < Test::Unit::TestCase
  DELTA = 0.0001

  EXPECTED = {
    ['mike', 'foo/one.rb'] => [3.0 / 3.0, 3.0 / 3.0],
    ['mike', 'foo/two.rb'] => [1.0 / 3.0, 1.0 / 2.0],
    ['mike', 'foo/three.rb'] => [2.0 / 3.0, 2.0 / 4.0],
    ['mike', 'foo/four.rb'] => [0.0 / 3.0, 0.0 / 1.0],
    ['bob', 'foo/one.rb'] => [0.0 / 2.0, 0.0 / 3.0],
    ['bob', 'foo/two.rb'] => [1.0 / 2.0, 1.0 / 2.0],
    ['bob', 'foo/three.rb'] => [2.0 / 2.0, 2.0 / 4.0],
    ['bob', 'foo/four.rb'] => [1.0 / 2.0, 1.0 / 1.0]
  }
  
  def test_metrics
    client = Mongo::Connection.new 'localhost', 27017
    client.drop_database 'test'
    db = client.db('test')

    fixtures = Mongo::Fixture.new(:commits, db)

    gen = Generator.new db
    gen.generate :author, {:out => 'authors'}
    gen.generate :path, {:out => 'paths'}

    metrics = Metrics.new db
    metrics.calculate_metrics.each do |k, v|
      expected = EXPECTED[k]
      actual = v
      (0..1).each { |i| assert_in_delta expected[i], actual[i], DELTA }
    end

    client.drop_database 'test'
  end
end
