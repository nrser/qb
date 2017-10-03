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
    
    # Find the only *.gemspec path in the `@path` directory. Warns and returns
    # `nil` if there is more than one match.
    def gemspec_path path
      paths = Pathname.glob( path.to_pn / '*.gemspec' )
      
      case paths.length
      when 0
        nil
      when 1
        paths[0]
      else
        warn "found multiple gemspecs: #{ paths }, unable to pick one."
        nil
      end
    end
    
  end # class << self (Eigenclass)
  
  
  # Attributes
  # ======================================================================
  
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `QB::Package::Gem`.
  def initialize
    
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  
end # class QB::Package::Gem



# Post-Processing
# =======================================================================
