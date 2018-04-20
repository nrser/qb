# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------
require 'nrser'
require 'nrser/core_ext'

# Project / Package
# -----------------------------------------------------------------------
require 'qb/errors'
require 'qb/python'
require 'qb/version'
require 'qb/util'
require 'qb/path'
require 'qb/data'


# Refinements
# =======================================================================

using NRSER::Types


# Definitions
# =======================================================================

module QB
  
  # Constants
  # =====================================================================
  
  # Absolute path to `//roles`.
  # 
  # @return [Pathname]
  # 
  GEM_ROLES_DIR = ROOT / 'roles'
  
  
  # Absolute path to the user's roles dir, which is `~/.ansible/roles`.
  # 
  # @return [Pathname]
  # 
  USER_ROLES_DIR = ENV['HOME'].to_pn / '.ansible' / 'roles'
  
  
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

require 'qb/package'

require 'qb/github'
