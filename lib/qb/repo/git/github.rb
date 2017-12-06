# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------
require 'qb/github'
require 'qb/repo/git'

# Refinements
# =======================================================================

require 'nrser/refinements'
using NRSER

require 'nrser/refinements/types'
using NRSER::Types


# Definitions
# =======================================================================

# Git repo where the `origin` remote points to GitHub, which is used to 
# determine it's owner and name.
# 
class QB::Repo::Git::GitHub < QB::Repo::Git
  
  # Constants
  # ======================================================================
  
  SSH_URL_RE = /^git@github\.com\:(?<owner>.*)\/(?<name>.*)\.git$/
  HTTPS_URL_RE = /^https:\/\/github\.com\/(?<owner>.*)\/(?<name>.*)\.git$/
  
  
  # Props
  # ---------------------------------------------------------------------
  
  ### Primary Properties
  
  prop :repo_id, type: QB::GitHub::RepoID
  
  
  ### Derived Properties
  
  
  # Class Methods
  # ======================================================================
  
  # Helpers
  # ---------------------------------------------------------------------
  
  def self.ssh_url? string
    SSH_URL_RE =~ string
  end
  
  
  def self.https_url? string
    HTTPS_URL_RE =~ string
  end
  
  
  def self.url? string
    ssh_url?( string ) || https_url?( string )
  end
  
  
  def self.parse_ssh_url string
    parse_url_with SSH_URL_RE, string
  end
  
  
  def self.parse_https_url string
    parse_url_with HTTPS_URL_RE, string
  end
  
  
  # Extract owner and name from Git remote URL string pointing to GitHub.
  # 
  # @return [nil]
  #   If the URL is not recognized.
  # 
  # @return [QB::GitHub::RepoID]
  #   If the URL successfully parses.
  # 
  def self.parse_url string
    parse_ssh_url( string ) || parse_https_url( string )
  end
  
  
  # Eigenclass (Singleton Class)
  # ========================================================================
  # 
  class << self
    protected
    # ========================================================================
      
      
      # @todo Document parse_url_with method.
      # 
      # @param [type] arg_name
      #   @todo Add name param description.
      # 
      # @return [return_type]
      #   @todo Document return value.
      # 
      def parse_url_with regexp, string
        if match = regexp.match( string )
          QB::GitHub::RepoID.new owner: match['owner'], name: match['name']
        end
      end # #parse_url_with
      
      
    # end protected
  end # class << self (Eigenclass)
  
  
  # Instance Methods
  # ======================================================================
  
  def api
    QB::GitHub::API.client.repo repo_id.path
  end
  
  
  def issue number
    # QB::GitHub::API.client.issue( repo_id.path, number ).to_h.stringify_keys
    QB::GitHub::Issue.find_by repo_id: repo_id, number: number
  end
  
  
end # class QB::Repo::Git::GitHub

