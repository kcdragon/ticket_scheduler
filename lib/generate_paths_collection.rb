require 'mongo'

class GeneratePathsCollection
  
  MAP = <<-MAP
    function() {
      for (var i in this.paths) {
        emit(this.paths[i], { "total_commits": 1, "authors": [{ "author" : this.author, "author_commits": 1 }] });
      }
    }
  MAP

  REDUCE = <<-REDUCE
    function(key, emits) {
      var result = { "total_commits" : 0, "authors" : [] };
      var result_authors = {};
      for (var i = 0; i < emits.length; i++) {
        result.total_commits += emits[i].total_commits;
        for (var j = 0; j < emits[i].authors.length; j++) {
          var author = emits[i].authors[j];
          if (!(author.author in result_authors)) {
            result_authors[author.author] = author.author_commits;
          }
          else {
            result_authors[author.author] += author.author_commits;
          }
        }
      }
      for (var author in result_authors) {
        result.authors.push({ "author": author, "author_commits": result_authors[author] });
      }
      return result;
    }
  REDUCE

  def initialize db
    @db = db
  end

  def generate_paths opts
    return @db['commits'].map_reduce MAP, REDUCE, opts
  end

end
