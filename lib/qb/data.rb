# encoding: UTF-8
# frozen_string_literal: true


# Definitions
# =======================================================================

# This class doesn't do *anything*... at least not yet. It serves as a marker
# for classes that are data (which must be {NRSER::Props}).
# 
# @example Testing Membership
#   object.is_a? QB::Data
#   
module QB
module Data
end; end # module QB::Data


# Post-Processing
# ========================================================================

require_relative './data/immutable'
