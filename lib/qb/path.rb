# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

require 'pathname'


# Deps
# -----------------------------------------------------------------------

require 'nrser'


# Package
# -----------------------------------------------------------------------


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


# @todo document QB::Path class.
class QB::Path < Pathname
  
  # Mixins
  # =====================================================================
  
  include NRSER::Meta::Props
  
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
  # Props
  # ======================================================================
  
  prop :raw, type: t.
  prop :expanded, type: t.pathname, source: :expand_path
  prop :exists, type: t.bool, source: :exists?
  prop :is_expanded, type: t.bool, source: :expanded?
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `QB::Path`.
  def initialize raw:, cwd: Pathname.getwd
    @raw = raw
    super @raw
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  # @return [Boolean]
  #   `true` if 
  def expanded?
    
  end
  
end # class QB::Path


# Post-Processing
# =======================================================================
