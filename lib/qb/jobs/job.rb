# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

require 'resque-retry'
require 'resque-lock-timeout'


# Project / Package
# -----------------------------------------------------------------------

require 'qb/jobs'

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
# Sets the queue name to {QB::Jobs.queue_name}.
# 
class Job
  
  
  # Mixins
  # ========================================================================
  
  include NRSER::Log::Mixin
  
  # Add retry support
  extend Resque::Plugins::Retry
  
  # Add job ID lock with timeout
  extend Resque::Plugins::LockTimeout
  
  
  # Config
  # ============================================================================
  
  logger.level = :trace
  
  
  # Class Methods
  # ========================================================================
  
  def self.instance
    @instance ||= new
  end
  
  
  def self.perform payload
    logger.trace "Performing job",
      payload: payload
    
    instance.perform payload['args']
  end
  
  
  def self.identifier payload
    logger.trace "Getting job identifier",
      payload: payload
    
    instance.identifier( payload['args'] ).tap { |identifier|
      logger.trace "Got job identifier: #{ identifier.inspect }"
    }
  end
  
end # class Job


# /Namespace
# =======================================================================

end # module Jobs
end # module QB
