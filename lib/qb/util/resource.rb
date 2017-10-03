# Requirements
# =======================================================================

# Deps
# -----------------------------------------------------------------------

require 'nrser'


# Refinements
# =======================================================================

require 'nrser/refinements'
using NRSER


# Declarations
# =======================================================================

module QB; end
module QB::Util; end


# Definitions
# =======================================================================

# Base class for QB "resources" - object representations of outside structures
# and concepts: things that live on disk, in remote systems or other runtimes.
# 
# At the moment, it's simply an extension of {NRSER::Meta::Props::Base}, but 
# it is here to serve as a centralized point to implement common behaviors,
# some of which would be lifted up to the {NRSER} properties system if they 
# prove sufficiently useful and general.
# 
class QB::Util::Resource < NRSER::Meta::Props::Base
end # class QB::Util::Resource
