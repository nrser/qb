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
    #   If `path` is the root directory of a Ruby gem.
    # 
    # @return [nil]
    #   If `path` is not the root directory of a Ruby gem.
    # 
    # @raise [QB::FSStateError]
    #   If `path` is not a directory.
    #     
    def from_root_path path, repo: NRSER::NO_ARG
      # Values we will use to construct the resource instance.
      values = {repo: repo}
      
      # Whatever we were passes is the reference path
      values[:ref_path] = path
      
      # Cast to {Pathname} if it's not already and expand it to create the 
      # root path
      values[:root_path] = path.to_pn.expand_path
      
      # Check that we're working with a directory, returning `nil` if we're not
      return nil unless values[:root_path].directory?
      
      # Get the path to the (single) Gemspec file.
      values[:gemspec_path] = self.gemspec_path values[:root_path]
      
      # Check that we got it, returning `nil` if we don't
      return nil if values[:gemspec_path].nil?
      
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
    
    
    # Like {.from_root_path} but raises an error if the path is not a gem
    # root directory.
    # 
    # @param path see .from_root_path
    # 
    # @return [QB::Package::Gem]
    # 
    # @raise [QB::FSStateError]
    #   -   If `path` is not a directory.
    #       
    #   -   If `path` is not a Gem directory.
    # 
    def from_root_path! path
      from_root_path( path ).tap { |gem|
        if gem.nil?
          raise QB::FSStateError.squished <<-END
            Path #{ path.inspect } does not appear to be the root directory
            of a Ruby gem.
          END
        end
      }
    end # #from_root_path!
    
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
  
  class State < NRSER::State:API
    class Dependencies < NRSER::State::API
      # 
      transform :input,
        t.label, :dependencies, t.label, true,
        to: {
          runtime: true,
        }
      
      # Prob not needed, just use value of `nil` to delete
      transform :input,
        t.label, :dependencies, t.label, false,
        to: {
          runtime: false,
          development: false,
        }
      
      def internal_read name
        QB::Package::Gem.from_root_path
      end
      
      def internal_write path, 
    end
    
    route(
      dependencies: 
    )
  end
  
end # class QB::Package::Gem

QB::Package::Gem::State.merge(
  'file://.' => {
    dependencies: {
      pry: {
        development: true,
      }
    }
  }
)

