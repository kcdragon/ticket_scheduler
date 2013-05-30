#!/usr/bin/env ruby

require 'rubygems'
require 'mongo'
require 'optparse'
require_relative 'db_connect'
require_relative 'logger'
require_relative 'parser'
require_relative 'generator'
require_relative 'metrics'

include Mongo

options = Hash.new
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: main.rb [options] dir file ...'

  options[:type] = :svn
  #opts.on('-t', '--type TYPE', [:svn, :git], 'Version Control System, currently supports SVN and Git') do |type|
  #  options[:type] = type
  #end

  options[:name] = 'default'
  opts.on('-n', '--name NAME', 'Name of Project') do |name|
    options[:name] = name
  end

  options[:include] = /.*/
  opts.on('-i', '--include REGEX', 'Include files that match this regular epxression') do |regex|
    options[:include] = /#{regex}/i
  end

  opts.on('-w', '--working-dir WD', 'Switch to working directory') do |wd|
    Dir.chdir wd
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

client = TicketScheduler::DbConnect.instance
client.drop_database options[:name] if not options[:skip]
db = client.set_database options[:name]

if not options[:skip]
  log_command = nil
  if options[:type] == :git
    log_command = lambda { |file| '<log>' + `git log --pretty=format:"<logentry revision='%h'><author>%an</author><date>%cd</date><msg>%s</msg></logentry>" #{file}` + '</log>' }
  else
    log_command = lambda { |file| `svn log --xml #{file}` }
  end

  #log_command = lambda { |file| `svn log --xml #{file}` }
  logger = Logger.new log_command, options[:include], options[:verbose]
  parser = Parser.new options[:verbose]
  logger.process *paths do |path, content|
    parser.parse path, content do |revision, commit|
      db['commits'].insert(commit) if db['commits'].find_one({:revision => revision}).nil?
      db['commits'].update({:revision => revision}, {'$push' => {:paths => path}})
      db['commits'].update({:revision => revision}, {'$inc' => {:paths_size => 1}})
    end
  end
else
  puts 'skipping generation of commits data' if options[:verbose]
end

gen = Generator.new db

opts = {:out => {:replace => 'authors'}} # send output to db
#opts = {:out => {:inline => true}, :raw => true} # send output to standard output=
gen.generate :author, opts

opts = {:out => {:replace => 'paths'}} # send output to db
#opts = {:out => {:inline => true}, :raw => true} # send output to standard output
gen.generate :path, opts

metrics = Metrics.new db
map = metrics.calculate_metrics

client.close
