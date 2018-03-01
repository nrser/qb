##
# I'm using Python's [doctest][] as a simple way of unit testing functions
# in plugins (just filter plugins at the moment, but no reason couldn't be
# used for simple tests in others as well).
# 
# [doctest]: https://docs.python.org/2/library/doctest.html
# 
# It's not a *great* solution, but it's simple, self-contained, and
# *something*... which is much, much better than trying to fiddle-test them
# through running roles (super slow).
# 
# This file serves as a driver to run the doctests as part of the RSpec suite.
# 
# The example group for each plugin is metadata tagged with it's repo-relative
# path like:
# 
#     plugin: "plugins/filter_plugins/version_plugins.py"
# 
# Allowing you to just test one file:
# 
#     rspec spec/plugins/doctests_spec.rb \
#       --tag plugin:plugins/filter_plugins/string_plugins.py
# 
# Each plugin file has only one RSpec example, which expects the exit status of
# 
#     python2 -m doctest -v <plugin_path>
# 
# to be 0, but it streams that command to STDOUT so you should be able to see
# what's going on.
# 
##

require 'nrser/refinements'
using NRSER


require 'qb'

# @todo document Doctest module.
module Doctest
  
  # See if a Python file is using `doctest`.
  # 
  # Ironically, I'm not using this function... I'm just running every file.
  # 
  def self.uses? path
    path.to_pn.read =~ /import\ doctest/
  end
  
  
  def self.file_paths
    # Pathname.glob( QB::ROOT / 'plugins' / '**' / '*.py' ).select { |path|
    #   uses? path
    # }
    Pathname.glob( QB::ROOT / 'plugins' / '**' / '*.py' )
  end
  
end # module Doctest


describe "Plugin Doctests" do
  Doctest.file_paths.each do |path|
    rel_path = path.relative_path_from QB::ROOT
    
    describe(
      rel_path.to_s,
      plugin: rel_path.to_s
    ) do
      it "should exit with status 0" do
        expect(
          Cmds.stream "python -m doctest -v <%= path %>", path: path
        ).to be 0
      end
    end
  end
end
