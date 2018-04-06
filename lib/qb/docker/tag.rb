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
require 'qb/package/version'


# Refinements
# =======================================================================

using NRSER::Types


# Declarations
# =======================================================================

module QB; end
module QB::Docker; end


# Definitions
# =======================================================================

# @todo document QB::Docker::Tag class.
class QB::Docker::Tag < QB::Util::Resource
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
  # Schema
  # ======================================================================
  
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
  
  invariant t.or  t.attrs( source:  t.not( t.nil ) ),
                  t.attrs( version: t.not( t.nil ) )
  
  # schema do
  #   prop  :string,
  #         type: t.non_empty_str,
  #         source: :to_s
  # 
  #   prop  :source,
  #         type: t.non_empty_str?,
  #         default: nil
  # 
  #   prop  :version,
  #         type: t.maybe( QB::Package::Version ),
  #         # default: nil
  #         default: ->( instance, **values ) {
  #           begin
  #             QB::Package::Version::From.docker_tag values[:source]
  #           rescue ArgumentError => error
  #             nil
  #           rescue TypeError => error
  #             nil
  #           end
  #         }
  # 
  #   invariant t.or  t.attrs( source:  t.not( t.nil ) ),
  #                   t.attrs( version: t.not( t.nil ) )
  # end
    
  
  # Instance Methods
  # ======================================================================
  
  def to_s
    source || version.docker_tag
  end
  
  
end # class QB::Docker::Tag
