require 'mongo'

# REFACTOR this should be a parent class with two child classes
# parent would contain all the logic and children would contain factory methods such as get_singular(), get_plural(), etc.
# this would remove the need for case statements and main.rb and generate_test.rb would simply instantiate a different class for each type of generation
class Generator
  
  def initialize db
    @db = db
  end
  
  # type: :path or :author
  def get_map type
    case type
    when :path
      key = 'this.paths[i]'
      value = 'this.author'
      singular = 'author'
    when :author
      key = 'this.author'
      value = 'this.paths[i]'
      singular = 'path'
    else
      raise "Invalid Type #{type}"
    end
    plural = singular + 's'
    map = <<-MAP
      function() {
        for (var i in this.paths) {
          emit(#{key}, { "total_commits": 1, "#{plural}": [{ "#{singular}" : #{value}, "#{singular}_commits": 1 }] });
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
    @db['commits'].map_reduce get_map(type), get_reduce(type), opts
    result = flatten_value_field type
    return result
  end

private
  # remove value embedded-document and make all keys in value embedded-document keys in the document
  def flatten_value_field type
    case type
    when :path
      coll = 'paths'
      values = 'authors'
    when :author
      coll = 'authors'
      values = 'paths'
    else
      raise "Invalid Type #{type}"
    end
    @db[coll].find.each do |e|
      @db[coll].remove({_id: e['_id']})
      @db[coll].insert({_id: e['_id'], 'total_commits' => e['value']['total_commits'], values => e['value'][values] })
    end
  end

end
