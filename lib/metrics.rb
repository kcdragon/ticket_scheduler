require 'mongo'

class Metrics  
  def initialize db
    @db = db
  end

  def calculate_metrics
    authors = []
    @db['authors'].find({}, fields: {_id: 1}).each { |a| authors << a['_id'] }
    
    paths = []
    @db['paths'].find({}, fields: {_id: 1}).each { |p| paths << p['_id'] }

    map = Hash.new # map [author, path] -> [metric1, metric2]
    authors.product(paths).each { |e| map[e] = [calculate_metric1(e[0], e[1]), calculate_metric2(e[0], e[1])] }
    return map
  end

private

  # TODO since each author will have the same total commits regardless of the path, this should be grabbed from the database (as well as the path total commits) before calculating metric1 and metric2
  
  # REFACTOR calculate_metric1 and calculate_metric2
  # might be able to do this with factory method or some simple lambda functios

  # metric1 is defined as the percentage of author's commits that path was in
  def calculate_metric1 author, path
    authors = @db['authors']
    author_commits = authors.find_one({_id: author}, fields: {_id: 0, 'total_commits' => 1})['total_commits']
    author = authors.find_one({_id: author})
    path = author['paths'].find {|p| p['path'] == path }
    if path.nil? # path will be nil if author has never commited path
      return 0
    end
    path_commits_for_author = path['path_commits']
    return 1.0 * path_commits_for_author / author_commits
  end

  # metric2 is defined as the percentage of all commits that path was in that author commited
  def calculate_metric2 author, path
    paths = @db['paths']
    path_commits = paths.find_one({_id: path}, fields: {_id: 0, 'total_commits' => 1})['total_commits']
    path = paths.find_one({_id: path})
    author = path['authors'].find {|a| a['author'] == author }
    if author.nil? # path will be nil if author has never commited path
      return 0
    end
    author_commits_for_path = author['author_commits']
    return 1.0 * author_commits_for_path / path_commits
  end
end
