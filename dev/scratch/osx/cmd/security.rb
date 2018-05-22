# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================


# Namespace
# =======================================================================

module  QB
module  OSX
module  Cmd


# Definitions
# =======================================================================

# Wrapper for the OSX `security` CLI.
# 
class Security < Cmds::Wrapper
  
  exe '/usr/bin/security'
  
  subcmd_format replace: { '_' => '-' }
  
  subcmd :add_generic_password,
    opts: {
      account_name: t.str,
    }
      
    
  
  subcmd :find_generic_password
  
  # Constants
  # ========================================================================
  
  
  # Class Methods
  # ========================================================================
  
  
  # @todo Document add_generic_password method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.add_generic_password arg_name
    # method body
  end # .add_generic_password
  
  
  
  # Attributes
  # ========================================================================
  
  
  # Construction
  # ========================================================================
  
  # Instantiate a new `Security`.
  def initialize
    
  end # #initialize
  
  
  # Instance Methods
  # ========================================================================
  
  
end # class Security


# /Namespace
# =======================================================================

end # module Cmd
end # module OSX
end # module QB
