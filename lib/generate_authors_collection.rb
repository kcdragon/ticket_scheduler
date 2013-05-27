require 'mongo'

MAP = <<-MAP
  function() {
    for (var i in this.paths) {
      emit(this.author, { "total_commits": 1, "paths": [{ "path": this.paths[i], "path_commits": 1 }] });
    }
  }
MAP

REDUCE = <<-REDUCE
  function(author, emits) {
    var result = { "total_commits" : 0, "paths" : [] };
    var result_paths = {};
    for (var i = 0; i < emits.length; i++) {
      result.total_commits += emits[i].total_commits;
      for (var j = 0; j < emits[i].paths.length; j++) {
        var path = emits[i].paths[j];
        if (!(path.path in result_paths)) {
          result_paths[path.path] = path.path_commits;
        }
        else {
          result_paths[path.path] += path.path_commits;
        }
      }
    }
    for (var path in result_paths) {
      result.paths.push({ "path": path, "path_commits": result_paths[path] });
    }
    return result;
  }
REDUCE

def generate_paths db, opts
  return db['commits'].map_reduce MAP, REDUCE, opts
end

conn = Mongo::Connection.new 'localhost', 27017 # TODO setup config file
db = conn['redmine'] # TODO this should reference -name argument in main,rb

# TODO REFACTOR need to make output location (stdout or db) a command line argument
#opts = {:out => {:replace => 'authors'}} # send output to db
opts = {:out => {:inline => true}, :raw => true} # send output to standard output
#paths = db['commits'].map_reduce map, reduce, opts
paths = generate_paths db, opts
puts paths.to_a

conn.close
