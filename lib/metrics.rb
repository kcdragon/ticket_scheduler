require 'mongo'

class Metrics  
  
  def calculate_metrics
    authors = []
    Author.each { |a| authors << a.name }
    
    paths = []
    Path.each { |p| paths << p.name }

    map = Hash.new # map [author, path] -> [metric1, metric2]
    authors.product(paths).each { |e| map[e] = [calculate_metric1(e[0], e[1]), calculate_metric2(e[0], e[1])] }
    return map
  end

private

  # TODO since each author will have the same total commits regardless of the path, this should be grabbed from the database (as well as the path total commits) before calculating metric1 and metric2
  
  # REFACTOR calculate_metric1 and calculate_metric2
  # might be able to do this with factory method or some simple lambda functios

  # metric1 is defined as the percentage of author's commits that path was in
  def calculate_metric1 author_name, path_name
    authors = Author
    author = authors.find(author_name)

    path = nil
    author.paths.each {|p| path = p if p.path == path_name }
    if path.nil? # path will be nil if author has never commited path
      return 0
    end
    path_commits_for_author = path.path_commits
    return 1.0 * path_commits_for_author / author.total_commits
  end

  # metric2 is defined as the percentage of all commits that path was in that author commited
  def calculate_metric2 author_name, path_name
    paths = Path
    path = paths.find(path_name)

    author = nil
    path.authors.each {|a| author = a if a.author == author_name }
    if author.nil? # path will be nil if author has never commited path
      return 0
    end
    author_commits_for_path = author.author_commits
    return 1.0 * author_commits_for_path / path.total_commits
  end
end
