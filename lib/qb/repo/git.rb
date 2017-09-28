require 'cmds'
require 'nrser/refinements/types'

using NRSER::Types

module QB 
module Repo

# Encapsulate information about a Git repository and expose useful operations as
# instance methods.
# 
# The main entry point is {QB::Repo::Git.from_path}, which creates a 
# 
class Git < NRSER::Meta::Props::Base
  GITHUB_SSH_URL_RE = /^git@github\.com\:(?<owner>.*)\/(?<name>.*)\.git$/
  GITHUB_HTTPS_URL_RE = /^https:\/\/github\.com\/(?<owner>.*)\/(?<name>.*)\.git$/
  
  class User < NRSER::Meta::Props::Base
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
  
  # @todo Document from_path method.
  # 
  # @param [String, Pathname] input_path
  #   A path that is in the Git repo.
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
  def self.from_path path, use_github_api: false
    raw_input_path = path
    
    # Create a Pathname from the input
    input_path = Pathname.new raw_input_path
    
    # input_path may point to a file, or something that doesn't even exist.
    # We want to ascend until we find an existing directory that we can cd into.
    closest_dir = input_path.ascend.find {|p| p.directory?}
    
    # Make sure we found something
    if closest_dir.nil?
      raise QB::FSStateError,
            "Unable to find any existing directory from path " +
            "#{ raw_input_path.inspect }"
    end
    
    # Change into the directory to make shell life easier
    Dir.chdir closest_dir do
      root_result = Cmds.capture "git rev-parse --show-toplevel"
      
      unless root_result.ok?
        raise QB::FSStateError,
              "Path #{ raw_input_path.inspect } does not appear to be in a " +
              "Git repo (looked in #{ closest_dir.inspect })."
      end
      
      root = Pathname.new root_result.out.chomp
      
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
      
      if origin && match = (
            GITHUB_SSH_URL_RE.match(origin) ||
            GITHUB_HTTPS_URL_RE.match(origin)
          )
        
        owner = match['owner']
        name = match['name']
        
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
        
      end
      
      new(
        raw_input_path: raw_input_path,
        input_path: input_path,
        root: root,
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
  
  
  # Props
  # =====================================================================
  
  prop :raw_input_path, type: t.path, default: nil, to_data: :to_s
  prop :root, type: t.pathname, to_data: :to_s
  prop :user, type: User
  prop :is_clean, type: t.bool
  prop :head, type: t.maybe(t.str), default: nil
  prop :branch, type: t.maybe(t.str), default: nil
  prop :origin, type: t.maybe(t.str), default: nil
  prop :owner, type: t.maybe(t.str), default: nil
  prop :name, type: t.maybe(t.str), default: nil
  prop :github, type: t.maybe(t.hash_), default: nil
  
  
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
  
  
  # Reading Repo State
  # ---------------------------------------------------------------------
  
  # @return [Boolean]
  #   `false` if the repo has any uncommitted changes or untracked files.
  # 
  def clean?
    is_clean
  end
  
end # class Git

end # module Repo
end # module QB
