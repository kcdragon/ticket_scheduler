require 'mongoid'

class PathAuthor
  include Mongoid::Document

  embedded_in :path, class_name: "Path", :inverse_of => :authors
  field :path, type: String
  field :path_commits, type: Integer
end

class Path
  include Mongoid::Document

  field :name, type: String
  field :_id, type: String, default: ->{ name }
  field :total_commits, type: Integer
  embeds_many :authors, class_name: "PathAuthor", :inverse_of => :path
end
