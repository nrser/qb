# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------
require 'cmds'
require 'git'

# Project / Package
# -----------------------------------------------------------------------
require 'qb/util/resource'


# Refinements
# =======================================================================

require 'nrser/refinements'
using NRSER

require 'nrser/refinements/types'
using NRSER::Types


# Declarations
# =======================================================================

module QB; end
class QB::Repo < QB::Util::Resource; end


# Definitions
# =======================================================================

# Encapsulate information about a Git repository and expose useful operations as
# instance methods.
# 
# The main entry point is {QB::Repo::Git.from_path}, which creates a 
# 
class QB::Repo::Git < QB::Repo
  GITHUB_SSH_URL_RE = /^git@github\.com\:(?<owner>.*)\/(?<name>.*)\.git$/
  GITHUB_HTTPS_URL_RE = /^https:\/\/github\.com\/(?<owner>.*)\/(?<name>.*)\.git$/
  
  class User < QB::Util::Resource
    prop :name, type: t.maybe(t.str), default: nil
    prop :email, type: t.maybe(t.str), default: nil
  end
  
  
  # class GitHubRemote < NRSER::Meta::Props::Base
  #   SSH_URL_RE = /^git@github\.com\:(?<owner>.*)\/(?<name>.*)\.git$/
  #   HTTPS_URL_RE = /^https:\/\/github\.com\/(?<owner>.*)\/(?<name>.*)\.git$/
  #   
  #   prop :owner,  type: t.str
  #   prop :name,   type: t.str
  #   prop :api_response, type: t.maybe(t.hash)
  #   
  #   prop :full_name,    type: t.str,  source: :full_name
  #   
  #   
  #   # Class Methods
  #   # =====================================================================
  #   
  #   # Test if a Git SSH or HTTPS remote url points to GitHub.
  #   # 
  #   # @param [String] url
  #   # 
  #   # @return [Boolean]
  #   # 
  #   def self.url? url
  #     SSH_URL_RE.match(url) || HTTPS_URL_RE.match(url)
  #   end # .url?
  #   
  #   
  #   # Instantiate an instance from a Git SSH or HTTPS remote url that points
  #   # to GitHub.
  #   # 
  #   # @param [type] arg_name
  #   #   @todo Add name param description.
  #   # 
  #   # @return [QB::Repo::Git::GitHubRemote]
  #   #   @todo Document return value.
  #   # 
  #   def self.from_url url, use_api: false
  #     match = SSH_URL_RE.match(git.origin) ||
  #             HTTPS_URL_RE.match(git.origin)
  #             
  #     unless match
  #       raise ArgumentError.new NRSER.squish <<-END
  #         url #{ url.inspect } does not match GitHub SSH or HTTPS patterns.
  #       END
  #     end
  #     
  #     owner = match['owner']
  #     name = match['name']
  #     
  #     if use_api
  #       
  #     end
  #   end # .from_url
  #   
  #   
  #   
  #   # @todo Document full_name method.
  #   # 
  #   # @param [type] arg_name
  #   #   @todo Add name param description.
  #   # 
  #   # @return [return_type]
  #   #   @todo Document return value.
  #   # 
  #   def full_name arg_name
  #     "#{ owner }/#{ name }"
  #   end # #full_name
  #   
  # end
  
  
  # Class Methods
  # =====================================================================
  
  # Factories
  # ---------------------------------------------------------------------
  # 
  # Class methods that instantiate an instance of {QB::Repo::Git}, specializing
  # it as a subclass when appropriate.
  # 
  
  # Instantiate a {QB::Package::Git} resource for whatever Git repo `path`
  # is in, or return `nil` if `path` is not in a Git repo.
  # 
  # @param [String, Pathname] path
  #   A path that may be in the Git repo.
  # 
  # @param [Boolean] use_github_api:
  #   When `true` will will contact the GitHub API for information to populate
  #   the {QB::Repo::Git#github} property for repos that have a GitHub origin
  #   URL.
  #   
  #   Otherwise we will just assume GitHub repos are private since it's the 
  #   safe guess, resulting in a {QB::Repo::Git#github} value of 
  #   `{private: true}`.
  # 
  # @return [QB::Repo::Git]
  #   If `path` is in a Git repo.
  # 
  # @return [nil]
  #   If `path` is not in a Git repo.
  # 
  # @raise [QB::FSStateError]
  #   -   If we can't find any existing directory to look in based on 
  #       `input_path`.
  # 
  def self.from_path path, use_github_api: false
    ref_path = path
    
    # Create a Pathname from the input
    input_path = Pathname.new ref_path
    
    # input_path may point to a file, or something that doesn't even exist.
    # We want to ascend until we find an existing directory that we can cd into.
    closest_dir = input_path.ascend.find {|p| p.directory?}
    
    # Make sure we found something
    if closest_dir.nil?
      raise QB::FSStateError,
            "Unable to find any existing directory from path " +
            "#{ ref_path.inspect }"
    end
    
    # Change into the directory to make shell life easier
    Dir.chdir closest_dir do
      root_result = Cmds.capture "git rev-parse --show-toplevel"
      
      unless root_result.ok?
        return nil
      end
      
      root_path = Pathname.new root_result.out.chomp
      
      user = User.new **NRSER.map_values(User.props.keys) {|key, _|
        begin
          Cmds.chomp! "git config user.#{ key }"
        rescue
        end
      }
      
      is_clean = Cmds.chomp!('git status --porcelain 2>/dev/null').empty?
      
      rev_parse = Cmds.capture 'git rev-parse HEAD'
      
      head = if rev_parse.ok?
        rev_parse.out.chomp
      end
      
      branch_result = Cmds.capture 'git branch --no-color 2> /dev/null'
      
      branch = if branch_result.ok?
        if line = branch_result.out.lines.find {|line| line.start_with? '*'}
          if m = line.match(/\*\s+(\S+)/)
            m[1]
          end
        end
      end
      
      origin = begin
        Cmds.chomp! "git remote get-url origin"
      rescue
      end
      
      owner = nil
      name = nil
      github = nil
      
      if origin && QB::Repo::Git::GitHub.url?( origin )
        
        repo_id = QB::Repo::Git::GitHub.parse_url origin
        
        if use_github_api
          github = OpenStruct.new
          github.api_url = "https://api.github.com/repos/#{ owner }/#{ name }"
          
          response = Net::HTTP.get_response URI(github.api_url)
          
          if response.is_a? Net::HTTPSuccess
            # parse response body and add everything to github result
            parsed = JSON.parse response.body
            parsed.each {|k, v| github[k] = v}
          else
            # assume it's private if we failed to find it
            github.private = true
          end
          
          github = github.to_h
        end
        
        return QB::Repo::Git::GitHub.new(
          ref_path: ref_path,
          input_path: input_path,
          root_path: root_path,
          user: user,
          is_clean: is_clean,
          head: head,
          branch: branch,
          origin: origin,
          repo_id: repo_id,
          owner: repo_id.owner,
          name: repo_id.name,
          github: github,
        )
        
      end
      
      new(
        ref_path: ref_path,
        input_path: input_path,
        root_path: root_path,
        user: user,
        is_clean: is_clean,
        head: head,
        branch: branch,
        origin: origin,
        owner: owner,
        name: name,
        github: github,
      )
      
    end # chdir
    
  end # .from_path
  
  
  # Instantiate a {QB::Package::Git} resource for whatever Git repo `path`
  # is in, raising an error if it's not in one.
  # 
  # @param [String, Pathname] path
  #   A path that is in the Git repo.
  # 
  # @param use_github_api: see #from_path
  # 
  # @return [QB::Repo::Git]
  # 
  # @raise [QB::FSStateError]
  #   -   If we can't find any existing directory to look in based on 
  #       `input_path`.
  #       
  #   -   If the directory we do find to look in does not seems to be part of
  #       a Git repo.
  # 
  def from_path! path, use_github_api: false
    from_path( path, use_github_api: use_github_api ).tap { |git|
      if git.nil?
        raise QB::FSStateError,
              "Path #{ path.inspect } does not appear to be in a " +
              "Git repo."
      end
    }
  end # #from_path!
  
  
  # Props
  # =====================================================================
  
  prop :user, type: User
  prop :is_clean, type: t.bool
  prop :head, type: t.maybe(t.str)
  prop :branch, type: t.maybe(t.str)
  prop :origin, type: t.maybe(t.str)
  prop :owner, type: t.maybe(t.str)
  prop :github, type: t.maybe(t.hash_)
  
  
  # Derived Properties
  # ---------------------------------------------------------------------
  
  prop :head_short, type: t.maybe(t.str), source: :head_short
  prop :full_name, type: t.maybe(t.str), source: :full_name
  prop :is_github, type: t.bool, source: :github?
  
  
  # Instance Methods
  # =====================================================================
  
  def full_name
    "#{ owner }/#{ name }" if owner && name
  end
  
  def head_short
    head[0...7] if head
  end
  
  def github?
    !github.nil?
  end
  
  def api    
    @api ||= ::Git.open root_path
  end
  
  
  # Reading Repo State
  # ---------------------------------------------------------------------
  
  # @return [Boolean]
  #   `false` if the repo has any uncommitted changes or untracked files.
  # 
  def clean?
    is_clean
  end
  
  
  def tags
    api.tags.map &:name
  end
  
end # class QB::Repo::Git


# Post-Processing
# =======================================================================

require 'qb/repo/git/github'
