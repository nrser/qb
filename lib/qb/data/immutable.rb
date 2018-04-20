# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Deps
# -----------------------------------------------------------------------

require 'nrser/props/immutable/hash'


# Project / Package
# -----------------------------------------------------------------------

require_relative '../data'


# Definitions
# =======================================================================

# Abstract base class for immutable data classes. Based off {Hamster::Hash}.
# 
# Using {Hamster::Hash}
# 
module  QB
module  Data
class   Immutable < Hamster::Hash
  
  # Mixins
  # ========================================================================
  
  # Mark as a "data" class. Maybe will add some functionality at some point...
  include QB::Data
  
  # Infrastructure for a prop'd class based on {Hamster::Hash}
  include NRSER::Props::Immutable::Hash
  
end; end; end # class QB::Data::Immutable
