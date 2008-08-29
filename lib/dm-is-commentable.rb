# Needed to import datamapper and other gems
require 'rubygems'
require 'pathname'

# Add all external dependencies for the plugin here
gem 'dm-core',          '>=0.9.5'
gem 'dm-types',         '>=0.9.5'
gem 'dm-timestamps',    '>=0.9.5'
gem 'dm-validations',   '>=0.9.5'
gem 'dm-aggregates',    '>=0.9.5'
gem 'dm-is-remixable',  '>=0.9.5'
gem 'dm-is-rateable',   '>=0.0.1'

require 'dm-core'
require 'dm-types'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-is-remixable'
require 'dm-is-rateable'

# Require plugin-files
require Pathname(__FILE__).dirname.expand_path / 'dm-is-commentable' / 'is' / 'commentable.rb'

# Include the plugin in Resource
DataMapper::Model.append_extensions DataMapper::Is::Commentable
