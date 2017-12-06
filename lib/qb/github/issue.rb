# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------
require 'qb/github/resource'


# Refinements
# =======================================================================

require 'nrser/refinements'
using NRSER

require 'nrser/refinements/types'
using NRSER::Types


# Declarations
# =======================================================================


# Definitions
# =======================================================================


# @todo document QB::GitHub::Issue class.
class QB::GitHub::Issue < QB::GitHub::Resource
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
  # @todo Document find method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.find_by repo_id:, number:
    new QB::GitHub::API.client.issue( repo_id.path, number )
  end # .find
  
  
  
  # Properties
  # ======================================================================
  
  prop :title, type: t.str, source: ->() { self[:title] }
  prop :title_filename, source: :title_filename
  
  # Constructor
  # ======================================================================
  
  # Instance Methods
  # ======================================================================
  
  def [] key
    @octokit_resource[key]
  end
  
  def title_filename
    
  end
  
end # class QB::GitHub::Issue



# Post-Processing
# =======================================================================
