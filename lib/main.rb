#!/usr/bin/env ruby

require 'rubygems'
require 'date'
require 'mongoid'
require 'optparse'

require_relative 'vc_logger'
require_relative 'parser'
require_relative 'generator'
require_relative 'metrics'
require_relative 'models/commit'
require_relative 'models/author'
require_relative 'models/path'

options = Hash.new
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: main.rb [options] dir file ...'

  options[:type] = :svn
  opts.on('-t', '--type TYPE', [:svn, :git], 'Version Control System, currently supports SVN and Git') do |type|
    options[:type] = type
  end

  options[:name] = 'default'
  opts.on('-n', '--name NAME', 'Name of Project') do |name|
    options[:name] = name
  end

  options[:include] = /.*/
  opts.on('-i', '--include REGEX', 'Include files that match this regular epxression') do |regex|
    options[:include] = /#{regex}/i
  end

  options[:wd] = '.'
  opts.on('-w', '--working-dir WD', 'Switch to working directory') do |wd|
    options[:wd] = wd
  end

  options[:skip] = false
  opts.on('-s', '--skip-data', 'Skip generation of data') do
    options[:skip] = true
  end

  options[:verbose] = false
  opts.on('-v', '--verbose', 'Verbose mode') do
    options[:verbose] = true
  end
  
  opts.on('-h', '--help', 'Display this screen') { puts opts; exit }
end
optparse.parse!

paths = ARGV

config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/mongoid.yml'
settings = Mongoid.load!(config_file, :development)

if not options[:skip]
  Commit.delete_all
  Author.delete_all
  Path.delete_all
end

if not options[:skip]
  log_command = nil
  if options[:type] == :git
    log_command = lambda do |file|
      '<log>' + `git log --pretty=format:"<logentry revision='%h'><author>%an</author><date>%cd</date><msg>%s</msg></logentry>" #{file}` + '</log>'
    end
    date_parser = lambda do |t| # Fri Oct 21 12:10:27 2011 +0200      
      Time.utc t[20..23], Date::ABBR_MONTHNAMES.index(t[4..6]), t[8..9], t[11..12], t[14..15], t[17..18]
    end
  else
    log_command = lambda { |file| `svn log --xml #{file}` }
    date_parser = lambda do |t| # "2011-04-11T19:21:57.549455Z"
      Time.utc t[0..3], t[5..6], t[8..9], t[11..12], t[14..15], t[17..18]
    end
  end

  Dir.chdir options[:wd]
  logger = Logger.new log_command, options[:include], options[:verbose]
  parser = Parser.new date_parser, options[:verbose]
  logger.process *paths do |path, content|
    parser.parse path, content do |revision, commit|
      # TODO need to test this with some "fake" SVN and Git logs      
      Commit.create(commit) if not Commit.where(revision: revision).exists?
      Commit.where(revision: revision).push(:paths, path)
      Commit.where(revision: revision).inc(:paths_size, 1)
    end
  end
else
  puts 'skipping generation of commits data' if options[:verbose]
end

gen = Generator.new

opts = {:out => {:replace => 'authors'}}
gen.generate :author, opts

opts = {:out => {:replace => 'paths'}}
gen.generate :path, opts

metrics = Metrics.new
map = metrics.calculate_metrics
