# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------

require 'qb/repo/git'

# Refinements
# =======================================================================


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
  
  
  # Instance Methods
  # ======================================================================
  
  
  
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
  
  
end # class QB::Repo::Git::GitHub

