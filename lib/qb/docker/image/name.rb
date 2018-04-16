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


# Refinements
# =======================================================================


# Declarations
# =======================================================================

module QB; end
module QB::Docker; end
module QB::Docker::Image; end


# Definitions
# =======================================================================

# @todo document QB::Docker::Image::Name class.
class QB::Docker::Image::Name < QB::Util::Resource
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
  # Props
  # ======================================================================
  
  
  
  prop  :tag,
        type: QB::Docker::Image::Tag,
        default: -> {
          QB::Docker::Image::Tag.new source: 'latest'
        }
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `QB::Docker::Image::Name`.
  def initialize
    
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  
end # class QB::Docker::Image::Name
