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


# Declarations
# =======================================================================


# Definitions
# =======================================================================


# @todo document QB::Ansible::Module::Response class.
class QB::Ansible::Module::Response < QB::Util::Resource
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
  # Props
  # ======================================================================
  
  prop :changed, type: t.bool, default: false
  prop :failed, type: t.bool, default: false
  
  prop :facts, type: t.hash_, default_from: Hash.method( :new )
  prop :warnings, type: t.array, default_from: Array.method( :new )
  
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `QB::Ansible::Module::Response`.
  def initialize
    
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  
end # class QB::Ansible::Module::Response
