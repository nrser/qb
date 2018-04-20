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

require_relative './image/name'
require_relative './image/tag'


# Refinements
# =======================================================================

require 'nrser/refinements/types'
using NRSER::Types


# Definitions
# =======================================================================

# @todo document Docker::Image class.
module  QB
module  Docker
class   Image < QB::Data::Immutable
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
  # Properties
  # ======================================================================
  
  prop :id, type: t.non_empty_str
  
  # prop :repo, type: QB::Docker::Repo
  # 
  # prop :tag, type: QB::Docker::Image::Tag
  
  
  # Instance Methods
  # ======================================================================
  
  
end; end; end # class QB::Docker::Image
