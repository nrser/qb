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
  
  # Construction
  # ========================================================================
  
  
  # Instance Methods
  # ========================================================================
  
  
  # Notifications
  # --------------------------------------------------------------------------
  
  def name
    self.class.name
  end
  
  
  def notify_options **options
    {
      title: "#{ self.class.name }",
      group: Process.pid,
    }.merge **options
  end
  
  
  def notify message, **options, &block
    QB::Jobs.notify message, notify_options( **options ), &block
  end
  
  
  def run! *args
    notify "Starting..."
    perform *args
    notify "SUCCESS"
  end
  
end # class Job


# /Namespace
# =======================================================================

end # module Jobs
end # module QB
