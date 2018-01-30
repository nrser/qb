# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------
require 'nrser'

# Project / Package
# -----------------------------------------------------------------------
require 'qb/util/resource'

# Refinements
# =======================================================================

using NRSER
using NRSER::Types


# Definitions
# =======================================================================

class QB::Repo::Git::User < QB::Util::Resource
  prop :name, type: t.maybe(t.str), default: nil
  prop :email, type: t.maybe(t.str), default: nil
end

# Post-Processing
# =======================================================================
