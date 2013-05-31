require 'mongoid'

class AuthorPath
  include Mongoid::Document

  embedded_in :author, class_name: "Author", :inverse_of => :paths
  field :path, type: String
  field :path_commits, type: Integer
end

class Author
  include Mongoid::Document

  field :name, type: String
  field :_id, type: String, default: ->{ name }
  field :total_commits, type: Integer
  embeds_many :paths, class_name: "AuthorPath", :inverse_of => :author
end
