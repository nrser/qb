#!/usr/bin/env ruby
##
# Basically, just a replacement for
# 
#     sed -i 's/git@github.com:/git:\/\/github.com\//' .gitmodules
# 
# 'cause `sed` works differently on OSX (BSD) and Linux (GNU).
# 
# Used as a temp HACK to swap SSH Git URLs for HTTPS in Travis.
# 
##

# Make sure we only run in CI
unless ENV['CI'] == 'true'
  $stderr.puts  "ERROR This script should only be run in CI! " \
                "(ENV['CI'] == 'true')"
  exit 1
end

require 'pathname'

path = Pathname.new( __dir__ ).join( '..', '..', '.gitmodules' ).expand_path
replaced = path.read.gsub /git\@github\.com\:/, 'git://github.com/'
path.write replaced
