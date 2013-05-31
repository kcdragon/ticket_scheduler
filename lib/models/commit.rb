require 'mongoid'

class Commit
  include Mongoid::Document

  field :author, type: String
  field :message, type: String
  field :paths, type: Array
  field :paths_size, type: Integer
  field :revision, type: String
  field :timestamp, type: DateTime

end
