# Requirements
# =======================================================================

# Deps
# -----------------------------------------------------------------------

require 'nrser'
require 'nrser/props/immutable/instance_variables'


# Declarations
# =======================================================================

module QB; end
module QB::Util; end


# Definitions
# =======================================================================

# Base class for QB "resources" - object representations of outside structures
# and concepts: things that live on disk, in remote systems or other runtimes.
# 
class QB::Util::Resource
  
  # Mixins
  # =====================================================================
  
  include NRSER::Props::Immutable::InstanceVariables
    
  
  def initialize values = {}
    initialize_props values
  end # #initialize
end # class QB::Util::Resource
