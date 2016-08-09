#!/usr/bin/env ruby

require 'json'

HERE = File.dirname(__FILE__)
GITIGNORE_DIR = File.expand_path File.join HERE, '..', 'files', 'gitignore'

Dir.chdir(GITIGNORE_DIR) do
  puts JSON.pretty_generate Dir['**/*.gitignore'].map {|path|
    path.match(/(.*)\.gitignore/)[1]
  }
end
