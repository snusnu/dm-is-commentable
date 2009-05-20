require 'pathname'

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
