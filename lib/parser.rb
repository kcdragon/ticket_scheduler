require 'hpricot'

class Parser
  def initialize verbose=false, out=$stdout, err=$stderr
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
  def parse_date_time t # svn - "2011-04-11T19:21:57.549455Z"
    Time.utc t[0..3], t[5..6], t[8..9], t[11..12], t[14..15], t[17..18]
  end
end
