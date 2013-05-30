require 'hpricot'

class Parser
  def initialize date_parser, verbose=false, out=$stdout, err=$stderr
    @date_parser = date_parser
    @verbose = verbose
    @out = out
    @err = err
  end

  def parse path, content, &block
    @out.puts "parsing log for #{path}" if @verbose
    Hpricot(content).search('/log/logentry').each do |entry|
      revision = entry['revision']
      commit = Hash.new
      commit[:revision] = revision
      commit[:author] = entry.children_of_type('author').first.inner_text
      commit[:timestamp] = parse_date_time entry.children_of_type('date').first.inner_text
      commit[:message] = entry.children_of_type('msg').first.inner_text
      yield revision, commit
    end
  end

private
  def parse_date_time t
    @date_parser.call(t)
  end
end
