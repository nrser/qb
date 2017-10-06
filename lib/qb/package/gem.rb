# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------
require 'qb/package'


# Refinements
# =======================================================================

require 'nrser/refinements'
using NRSER

require 'nrser/refinements/types'
using NRSER::Types


# Definitions
# =======================================================================

# Package resource for a Ruby Gem.
# 
class QB::Package::Gem < QB::Package
  
  # Constants
  # ======================================================================
  
  
  # Eigenclass (Singleton Class)
  # ========================================================================
  # 
  class << self
    
    # Find the only `*.gemspec` path in the `root_path` Gem directory.
    # 
    # @param [String | Pathname] root_path
    #   Path to the gem's root directory.
    # 
    def gemspec_path root_path
      paths = Pathname.glob( root_path.to_pn / '*.gemspec' )
      
      case paths.length
      when 0
        nil
      when 1
        paths[0]
      else
        nil
      end
    end # #gemspec_path
    
    
    # @todo Document from_path method.
    # 
    # @param [String | Pathname] path
    #   Path to gem root directory.
    # 
    # @return [QB::Package::Gem]
    # 
    # @raise [QB::FSStateError]
    #   -   If `path` is not a directory.
    #       
    #   -   If `path` is not a Gem directory.
    #       
    def from_root_path path
      # Values we will use to construct the resource instance.
      values = {}
      
      # Whatever we were passes is the reference path
      values[:ref_path] = path
      
      # Cast to {Pathname} if it's not already and expand it to create the 
      # root path
      values[:root_path] = path.to_pn.expand_path
      
      # Check that we're working with a directory
      unless values[:root_path].directory?
        raise QB::FSStateError.squished <<-END
          Path #{ path.inspect } is not a directory.
        END
      end
      
      # Get the path to the (single) Gemspec file.
      values[:gemspec_path] = self.gemspec_path values[:root_path]
      
      # Check that we got it
      if values[:gemspec_path].nil?
        raise QB::FSStateError.squished <<-END
          Unable to find sole `.gemspec` file in #{ values[:root_path].to_s }
          directory.
        END
      end
      
      # Load up the gemspec ad version
      values[:spec] = ::Gem::Specification::load values[:gemspec_path].to_s
      
      # Get the name from the spec
      values[:name] = values[:spec].name
      
      # Get the version from the spec
      values[:version] = QB::Package::Version.from_gem_version \
        values[:spec].version
      
      # Construct the resource instance and return it.
      new **values
    end # #from_root_path
    
    
  end # class << self (Eigenclass)
  
  
  # Properties
  # =====================================================================
  
  # Principle Properties
  # ---------------------------------------------------------------------
  
  prop  :gemspec_path,
        type: t.file_path
        
  prop  :spec,
        type: ::Gem::Specification
  
  
  # Instance Methods
  # ======================================================================
  
end # class QB::Package::Gem
