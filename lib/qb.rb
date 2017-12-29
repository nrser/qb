# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------
require 'nrser/extras'

# Project / Package
# -----------------------------------------------------------------------
require 'qb/errors'
require 'qb/version'
require 'qb/util'
require 'qb/path'


# Refinements
# =======================================================================

require 'nrser/refinements'
using NRSER

require 'nrser/refinements/types'
using NRSER::Types


# Definitions
# =======================================================================

module QB
  
  # Constants
  # =====================================================================
  
  ROOT = (Pathname.new(__FILE__).dirname + '..').expand_path
  GEM_ROLES_DIR = ROOT + 'roles'
  USER_ROLES_DIR = Pathname.new(ENV['HOME']).join '.ansible', 'roles'
  
  
  # Mixins
  # =====================================================================
  
  include SemanticLogger::Loggable
  
  
  # Support for the old custom debug logging, now sent to {SemanticLogger}.
  # 
  def self.debug *args
    if args[0].is_a? String
      logger.debug *args
    else
      # De-array if there's only one arg
      args = args[0] if args.length == 1
      # And send the args to SM as the payload
      logger.debug payload: args
    end
  end
    
end


# Post-Processing
# =======================================================================

# needs QB::*_ROLES_DIR
require 'qb/role'
require 'qb/options'
require 'qb/repo'
require 'qb/cli'

require 'qb/ansible'
# Depreciated namespace:
require 'qb/ansible_module'

require 'qb/package'

require 'qb/github'
