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


# Definitions
# =======================================================================

# @todo document QB::Docker::Image::Name class.
class QB::Docker::Image::Name < QB::Util::Resource
  
  module Types
    OWNER = t.maybe t.path_segment
    REPO_NAME = t.path_segment
  end
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
  # Props
  # ======================================================================
  
  prop :host, type: t.maybe( QB::Docker::Image::Host )
  prop :owner, type: Types::OWNER
  prop :repo_name, type: Types::REPO_NAME
  prop :tag, type: QB::Docker::Image::Tag, default: 'latest'
  
  
  # Instance Methods
  # ======================================================================
  
  
end # class QB::Docker::Image::Name


# Post-Processing
# =======================================================================
