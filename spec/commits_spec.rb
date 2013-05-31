require 'mongoid'

require_relative '../lib/models/commit'
require_relative '../test/test_helper'

describe Commit do
  before :all do
    config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/mongoid.yml'
    Mongoid.load!(config_file, :development)
    Mongoid.connect_to('test')

    Commit.delete_all
    inserted = TestHelper.insert_commits
  end

  it "should have 5 total commits" do
    expect(Commit.count).to eq(5)
  end

  describe "mike's commits" do
    before :all do
      @mike = Commit.where(author: 'mike')
    end

    it "should exist" do
      @mike.exists?.should be_true
    end

    it "should have 3 commits" do
      expect(@mike.count).to eq(3)
    end
  end
end
