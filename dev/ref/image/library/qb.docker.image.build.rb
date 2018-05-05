#!/usr/bin/env ruby
# WANT_JSON

# Load QB's Ansible module scripting harness
load ENV['QB_AM_SCRIPT_PATH']

require 'qb'

arg :path, type: t.dir_path

source = QB::Docker::Image::Source.from_path path
