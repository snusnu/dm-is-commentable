# Needed to import datamapper and other gems
require 'rubygems'
require 'pathname'

# Add all external dependencies for the plugin here
gem 'dm-core', '=0.9.4'
gem 'dm-is-remixable', '=0.9.4'

require 'dm-core'
require 'dm-is-remixable'

# Require plugin-files
require Pathname(__FILE__).dirname.expand_path / 'dm-is-commentable' / 'is' / 'commentable.rb'

# Include the plugin in Resource
module DataMapper
  module Resource
    module ClassMethods
      include DataMapper::Is::Commentable
    end # module ClassMethods
  end # module Resource
end # module DataMapper
