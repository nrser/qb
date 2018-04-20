# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Need mutable props mixin
require 'nrser/props/immutable/instance_variables'

# Need {Time#iso8601_for_idiots}
require 'nrser/core_ext/time'

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================


# Declarations
# =======================================================================


# Definitions
# =======================================================================


# An object that encapsulates an execution of the QB program.
# 
class QB::Execution
  
  # Constants
  # ========================================================================
  
  
  # Mixins
  # ========================================================================
  
  include NRSER::Props::Mutable::InstanceVariables
  
  
  # Class Methods
  # ========================================================================
  
  
  # Props
  # ========================================================================
  
  # @!attribute [r]
  prop  :started_at,
        type: Time,
        writer: false,
        default: -> { Time.current }
  
  prop  :pid,
        type: Fixnum,
        source: -> { Process.pid }
  
  prop  :id,
        type: String,
        source: -> { "#{ self.started_at }-pid_#{ self.pid }" }
  
  # Construction
  # ========================================================================
  
  # Instantiate a new `QB::Execution`.
  def initialize values = {}
    initialize_props values
  end # #initialize
  
  
  # Instance Methods
  # ========================================================================
  
  
end # class QB::Execution
