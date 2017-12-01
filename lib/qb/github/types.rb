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

require 'nrser/refinements'
using NRSER

require 'nrser/refinements/types'
using NRSER::Types


# Declarations
# =======================================================================

module QB; end
module QB::GitHub; end


# Definitions
# =======================================================================

module QB::GitHub::Types
  
  def self.repo_name
    t.path_seg name: 'GitHubRepoName(String)'
  end
  
  def self.repo_owner
    t.path_seg name: 'GitHubRepoOwner(String)'
  end
  
end # module QB::GitHub::Types

