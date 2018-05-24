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
module  Docker
module  Jobs
module  Image


# Definitions
# =======================================================================

# @todo document PushJob class.
class PushJob
  
  # Constants
  # ========================================================================
  
  
  # Class Methods
  # ========================================================================
  
  # @todo Document perform method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.perform name
    notify "PUSHING Docker image #{ name }..."
    QB::Docker::CLI.push name
    notify "Docker image #{ name } PUSHED."
  end # .perform
  
  
end # class PushJob


# /Namespace
# =======================================================================

end # module Image
end # module Jobs
end # module Docker
end # module QB
