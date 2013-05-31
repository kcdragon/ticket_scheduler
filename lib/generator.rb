require 'mongo'

require_relative '../lib/models/author'
require_relative '../lib/models/path'

# REFACTOR this should be a parent class with two child classes
# parent would contain all the logic and children would contain factory methods such as get_singular(), get_plural(), etc.
# this would remove the need for case statements and main.rb and generate_test.rb would simply instantiate a different class for each type of generation
class Generator
  
  # type: :path or :author
  def get_map type
    case type
    when :path
      key = 'this.paths[i]'
      value = 'this.author'
      singular = 'author'
      total_commits = '1'
    when :author
      key = 'this.author'
      value = 'this.paths[i]'
      singular = 'path'
      total_commits = '(i == 0 ? 1 : 0)' # when author is the key, we only want to emit once with a total_commit value
    else
      raise "Invalid Type #{type}"
    end
    plural = singular + 's'
    map = <<-MAP
      function() {
        for (var i in this.paths) {
          emit(#{key}, { "total_commits": #{total_commits}, "#{plural}": [{ "#{singular}" : #{value}, "#{singular}_commits": 1 }] });
        }
      }
    MAP
    return map
  end

  def get_reduce type
    case type
    when :path
      singular = 'author'
    when :author
      singular = 'path'
    else
      raise "Invalid Type #{type}"
    end
    plural = singular + 's'
    reduce = <<-REDUCE
      function(key, emits) {
        var result = { "total_commits" : 0, "#{plural}" : [] };
        var result_#{plural} = {};
        for (var i = 0; i < emits.length; i++) {
          result.total_commits += emits[i].total_commits;
          for (var j = 0; j < emits[i].#{plural}.length; j++) {
            var #{singular} = emits[i].#{plural}[j];
            if (!(#{singular}.#{singular} in result_#{plural})) {
              result_#{plural}[#{singular}.#{singular}] = #{singular}.#{singular}_commits;
            }
            else {
              result_#{plural}[#{singular}.#{singular}] += #{singular}.#{singular}_commits;
            }
          }
        }
        for (var #{singular} in result_#{plural}) {
          result.#{plural}.push({ "#{singular}": #{singular}, "#{singular}_commits": result_#{plural}[#{singular}] });
        }
        return result;
      }
    REDUCE
    return reduce
  end
  
  def generate type, opts
    output = type == :author ? 'authors_temp' : 'paths_temp'
    embedded = type == :author ? 'paths' : 'authors'
    coll = type == :author ? Author : Path
    
    Commit.map_reduce(get_map(type), get_reduce(type)).out(inline: 1).each do |hash|
      coll.create({name: hash['_id'], total_commits: hash['value']['total_commits'], embedded => hash['value'][embedded] })
    end
  end

private
  # remove value embedded-document and make all keys in value embedded-document keys in the document
  def flatten_value_field type
    case type
    when :path
      coll = 'paths'
      values = 'authors'
      c = Path
    when :author
      coll = 'authors'
      values = :paths
      c = Author
    else
      raise "Invalid Type #{type}"
    end
    #@db[coll].find.each do |e|
    #  @db[coll].remove({_id: e['_id']})
    #  @db[coll].insert({_id: e['_id'], 'total_commits' => e['value']['total_commits'], values => e['value'][values] })
    #end
    db = c.collection.database # doesn't matter which Model we call collection from, we just need the database
    puts db['authors_temp'].find.to_a
    db['authors_temp'].find.each do |e|
      puts e['_id']
      db['authors_temp'].find('_id' => e['_id']).remove
      c.create({_id: e['_id'], total_commits: e['value']['total_commits'], values => e['value'][values] })
    end
  end

end
