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


# Definitions
# =======================================================================


# @todo document QB::Options::Types module.
module QB::Options::Types
  extend t::Factory
  
  def_factory :glob do
    t.array t.path, name: 'FileGlob', from_s: ->( glob ) {
      if glob.start_with? '//'
        glob = NRSER.git_root( Dir.getwd ).join( glob[2..-1] ).to_s
      end
      
      Dir[glob]
    }
  end
  
end # module QB::Options::Types
