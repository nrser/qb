#!/usr/bin/env ruby

require 'bundler/setup'

require 'pp'
require 'json-schema'
require 'yaml'

opt_defs = YAML.load File.read(File.join(File.dirname(__FILE__), 'schemas.yml'))

pp opt_defs

schemas = opt_defs.map {|opt_def|
  JSON::Schema.new opt_def['type'], Addressable::URI.parse('http://example.com/my-schema')
}

pp schemas
