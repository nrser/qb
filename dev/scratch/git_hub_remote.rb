# Removed from {QB::Repo::Git}, where it was commented-out at the time

class GitHubRemote < NRSER::Meta::Props::Base
  SSH_URL_RE = /^git@github\.com\:(?<owner>.*)\/(?<name>.*)\.git$/
  HTTPS_URL_RE = /^https:\/\/github\.com\/(?<owner>.*)\/(?<name>.*)\.git$/
  
  prop :owner,  type: t.str
  prop :name,   type: t.str
  prop :api_response, type: t.maybe(t.hash)
  
  prop :full_name,    type: t.str,  source: :full_name
  
  
  # Class Methods
  # =====================================================================
  
  # Test if a Git SSH or HTTPS remote url points to GitHub.
  #
  # @param [String] url
  #
  # @return [Boolean]
  #
  def self.url? url
    SSH_URL_RE.match(url) || HTTPS_URL_RE.match(url)
  end # .url?
  
  
  # Instantiate an instance from a Git SSH or HTTPS remote url that points
  # to GitHub.
  #
  # @param [type] arg_name
  #   @todo Add name param description.
  #
  # @return [QB::Repo::Git::GitHubRemote]
  #   @todo Document return value.
  #
  def self.from_url url, use_api: false
    match = SSH_URL_RE.match(git.origin) ||
            HTTPS_URL_RE.match(git.origin)
            
    unless match
      raise ArgumentError.new NRSER.squish <<-END
        url #{ url.inspect } does not match GitHub SSH or HTTPS patterns.
      END
    end
    
    owner = match['owner']
    name = match['name']
    
    if use_api
      
    end
  end # .from_url
  
  
  
  # @todo Document full_name method.
  #
  # @param [type] arg_name
  #   @todo Add name param description.
  #
  # @return [return_type]
  #   @todo Document return value.
  #
  def full_name arg_name
    "#{ owner }/#{ name }"
  end # #full_name
  
end
