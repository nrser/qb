# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------

require 'qb/data'

require 'qb/package/version'


# Refinements
# =======================================================================

require 'nrser/refinements/types'
using NRSER::Types



# Namespace
# ============================================================================

module  QB
module  Docker
class   Image < QB::Data::Immutable

# Definitions
# =======================================================================

# A Docker image tag, with support for paring versions.
# 
class Tag   < QB::Data::Immutable
  
  include NRSER::Log::Mixin
  
  
  # @todo Document from_s method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.from_s string
    new source: string
  end # .from_s
  
  
  # @!group Props
  # ==========================================================================
  
  prop  :string,
        type: t.non_empty_str,
        source: :to_s
  
  prop  :source,
        type: t.non_empty_str?,
        default: nil
  
  prop  :version,
        type: t.maybe( QB::Package::Version ),
        default: ->( source: ) {
          begin
            QB::Package::Version::From.docker_tag source
          rescue ArgumentError => error
            nil
          rescue TypeError => error
            nil
          end
        }
  
  # @!endgroup Props # *******************************************************
  
  
  invariant t.attrs( source:  ~t.nil ) |
            t.attrs( version: ~t.nil )
  
  # Instance Methods
  # ======================================================================
  
  def to_s
    if version
      version.docker_tag
    else
      source
    end
  end
  
  
  def dirty?
    version && version.build_dirty?
  end
  
  
end # class Tag


# /Namespace
# ============================================================================

end # module  QB
end # module  Docker
end # class   Image < QB::Data::Immutable
