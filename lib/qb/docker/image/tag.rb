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


# Definitions
# =======================================================================

# A Docker image tag, with support for paring versions.
# 
module  QB
module  Docker
class   Image < QB::Data::Immutable
class   Tag   < QB::Data::Immutable
  
  
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
  
  
  invariant t.or  t.attrs( source:  t.not( t.nil ) ),
                  t.attrs( version: t.not( t.nil ) )
  
  # Instance Methods
  # ======================================================================
  
  def to_s
    source || version.docker_tag
  end
  
  
end; end; end; end # class QB::Docker::Image::Tag
