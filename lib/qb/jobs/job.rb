# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------
require 'yaml'

# Deps
# -----------------------------------------------------------------------
require 'rocketjob'

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================


# Namespace
# =======================================================================

module  QB
module  Jobs


# Definitions
# =======================================================================

# Base class for QB jobs.
# 
class Job < RocketJob::Job
  
  # Constants
  # ========================================================================
  
  
  # Class Methods
  # ========================================================================
  
  
  # @todo Document create! method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.create! *args, &block
    QB::Jobs.init!
    super *args, &block
  end # .create!
  
  
  # Attributes
  # ========================================================================
  
  
  # Construction
  # ========================================================================
  
  
  # Instance Methods
  # ========================================================================
  
  
end # class Job


# /Namespace
# =======================================================================

end # module Jobs
end # module QB
