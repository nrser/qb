# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------
require 'qb/util/resource'
require 'qb/github/types'


# Refinements
# =======================================================================

require 'nrser/refinements'
using NRSER

require 'nrser/refinements/types'
using NRSER::Types


# Definitions
# =======================================================================


# Unique identifier for a GitHub repo, which is a composite of an `owner`
# and a `name` string.
# 
class QB::GitHub::RepoID < QB::Util::Resource
  
  # Configuration
  # =====================================================================
  
  # Props
  # ---------------------------------------------------------------------
  
  ### Primary Properties
  
  prop :owner, type: QB::GitHub::Types.repo_owner
  prop :name, type: QB::GitHub::Types.repo_name
  
  
  ### Derived Properties
  
  prop :path, type: t.non_empty_str, source: :path
  prop :full_name, type: t.maybe(t.str), source: :full_name
  
  
  # Class Methods
  # ======================================================================
  
  
  # Instance Methods
  # ======================================================================
  
  # "Path" on GitHub for the repo - the `<owner>/<name>` part that comes 
  # after the host in URLs. 
  # 
  # Called `full_name` in GitHub API (we include a `#full_name` method alias 
  # as well).
  # 
  # This is also what we return for {#to_s}.
  # 
  # @example
  #   repo_id = QB::GitHub::RepoID.new owner: 'nrser', name: 'qb'
  #   repo_id.path
  #   # => "nrser/qb"
  # 
  # @return [String]
  # 
  def path
    "#{ owner }/#{ name }"
  end # #path
  
  alias_method :full_name,  :path
  alias_method :to_s,       :path
  

  # SSH protocol URL string for use as a Git remote.
  # 
  # @example
  #   repo_id = QB::GitHub::RepoID.new owner: 'nrser', name: 'qb'
  #   repo_id.git_ssh_url
  #   # => "git@github.com:nrser/qb.git"
  # 
  # @return [String]
  # 
  def git_ssh_url
    "git@github.com:#{ path }.git"
  end # #to_git_ssh_url
  
  
  # HTTPS protocol URL string for use as a Git remote.
  # 
  # @example
  #   repo_id = QB::GitHub::RepoID.new owner: 'nrser', name: 'qb'
  #   repo_id.git_https_url
  #   # => "https://github.com/nrser/qb.git"
  # 
  # @return [String]
  # 
  def git_https_url
    "https://github.com/#{ path }.git"
  end
  
  
  # Return {#git_ssh_url} or {#git_https_url} depending on `protocol`
  # parameter.
  # 
  # @param [Symbol] protocol
  #   `:ssh` or `:https`.
  # 
  # @return [String]
  #   URL.
  # 
  def git_url protocol
    t.match protocol,
      :ssh,   ->( _ ) { git_ssh_url },
      :https, ->( _ ) { git_https_url }
  end # #to_url
  
  
end # class QB::GitHub::RepoID
