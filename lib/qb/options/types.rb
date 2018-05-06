# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

require 'nrser/refinements/types'

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================

using NRSER::Types


# Namespace
# ========================================================================

module  QB
class   Options


# Definitions
# =======================================================================

# Custom types, available by factory name in QB metadata. Neat huh?!
# 
module  Types
  extend t::Factory
  
  # A valid variable name string.
  # 
  def_factory :var_name do |name: 'VarName', **options|
    t.and \
      t.str,
      t.when( /\A[a-zA-Z][0-9a-zA-Z\_]*\z/ ),
      name: name,
      **options
  end
  
  
  def_factory :glob do
    t.array t.path, name: 'FileGlob', from_s: ->( glob ) {
      if glob.start_with? '//'
        glob = NRSER.git_root( Dir.getwd ).join( glob[2..-1] ).to_s
      end
      
      Dir[glob]
    }
  end
  
  
  def_factory(
    :qb_default_dir_strategy,
    aliases: [ :default_dir_strategy ],
  ) do |name: 'QBDefaultDirStrategy', **options|
    t.one_of \
      t.nil,
      t.false,
      'cwd',
      'git_root',
      t.shape( 'exe'        => t.path ),
      t.shape( 'find_up'    => t.rel_path ),
      t.shape( 'from_role'  => t.non_empty_str ),
      name: name,
      **options
  end
  
  
  def_factory(
    :qb_default_dir,
    aliases: [ :default_dir ],
  ) do |name: 'QBDefaultDir', **options|
    t.one_of \
      qb_default_dir_strategy,
      t.array( qb_default_dir_strategy ),
      **options
  end
  
end # module Types


# /Namespace
# ========================================================================

end # class   Options
end # module  QB
