require 'mongo'

conn = Mongo::Connection.new 'localhost', 27017
db = conn['redmine']

map = <<-MAP
  function() {
    for (var i in this.paths) {
      emit(this.paths[i], { "total_commits": 1, "authors": [{ "author" : this.author, "author_commits": 1 }] });
    }
  }
MAP

reduce = <<-REDUCE
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

#opts = {:out => {:replace => 'paths'}, :verbose => true}
opts = {:out => {:inline => true}, :raw => true, :verbose => true}
paths = db['commits'].map_reduce map, reduce, opts
puts paths.to_a

conn.close
