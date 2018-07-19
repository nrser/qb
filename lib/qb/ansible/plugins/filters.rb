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
module  Ansible
module  Plugins


# Definitions
# =======================================================================

# Filter plugin methods to expose to Ansible's Jinja2 templates.
module Filters

  def self.drop_ext path
    File.basename File.basename( path, File.extname( path ) ), '.tar'
  end
  
end # module Filters


# /Namespace
# =======================================================================

end # module Plugins
end # module Ansible
end # module QB
