# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------

require 'qb/util/resource'

require_relative './package/version'


# Refinements
# =======================================================================

require 'nrser/refinements'
using NRSER


# Declarations
# =======================================================================

module QB; end


# Definitions
# =======================================================================

# Common properties and methods of package resources, aimed at packages
# represented as directories in projects.
# 
class QB::Package < QB::Util::Resource
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
  # Properties
  # ======================================================================
  
  prop  :version, type: QB::Package::Version
  
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `QB::Package`.
  def initialize
    
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  
end # class QB::Package

