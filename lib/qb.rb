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
  
  
  def self.debug *args
    if args[0].is_a? String
      logger.debug *args
    else
      logger.debug payload: args
    end
    
    # return unless ENV['QB_DEBUG'] && args.length > 0
    # 
    # header = 'DEBUG'
    # 
    # if args[0].is_a? String
    #   header += " " + args.shift
    # end
    # 
    # dumpObj = case args.length
    # when 0
    #   header
    # when 1
    #   {header => args[0]}
    # else
    #   {header => args}
    # end
    # 
    # # $stderr.puts("DEBUG " + format(msg, values))
    # $stderr.puts dumpObj.pretty_inspect
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
