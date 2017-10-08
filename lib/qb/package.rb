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

require 'nrser/refinements/types'
using NRSER::Types


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
  
  # @!attribute [r] ref_path
  #   User-provided path value used to construct the resource instance, if any.
  #   
  #   This may not be the same as a root path for the resource, such as with
  #   resource classes that can be constructed from any path *inside* the 
  #   directory, like a {QB::Repo::Git}.
  #   
  #   @return [String | Pathname]
  #     If the resource instance was constructed based on a path argument.
  #   
  #   @return [nil]
  #     If the resource instance was *not* constructed based on a path 
  #     argument.
  #   
  prop  :ref_path, type: t.maybe( t.dir_path )
  
  
  # @!attribute [r] root_path
  #   Absolute path to the gem's root directory.
  #   
  #   @return [Pathname]
  #   
  prop  :root_path, type: t.dir_path
  
  
  # @!attribute [r] version
  #   Version of the package.
  # 
  #   @return [QB::Package::Version]
  # 
  prop  :version, type: QB::Package::Version
  
  
  # @!attribute [r] name
  #   The string name the package goes by.
  # 
  #   @return [String]
  #     Non-empty string.
  # 
  prop  :name, type: t.non_empty_str
  
  
end # class QB::Package


# Post-Processing
# =======================================================================

require_relative './package/gem'

