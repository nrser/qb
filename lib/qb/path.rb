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
  
  
  # Props
  # ======================================================================
  
  prop  :cwd,
        type: t.pathname
  
  prop  :raw,
        type: t.path,
        to_data: :to_s
  
  prop  :expanded,
        type: t.path,
        source: ->() { expand_path.to_s }
  
  prop  :exists,
        type: t.bool,
        source: :exist?
  
  prop  :is_expanded,
        type: t.bool,
        source: :expanded?
  
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `QB::Path`.
  # def initialize raw:, cwd: Pathname.getwd, **values
  #   super raw: raw, cwd: cwd, **values
  #   @path = Pathname.new raw
  # end # #initialize
  
  def initialize arg
    case arg
    when Hash
      super arg[:raw]
      initialize_props cwd: Pathname.getwd, **arg
    else
      super arg
      initialize_props raw: arg, cwd: Pathname.getwd
    end
  end # #initialize
  
  # Instance Methods
  # ======================================================================
  
  # @return [Boolean]
  #   `true` if 
  def expanded?
    self == expand_path
  end
  
end # class QB::Path

