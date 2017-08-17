require 'cmds'

module QB 
module Repo

# Encapsulate information about a Git repository and expose useful operations as
# instance methods.
# 
# The main entry point is {QB::Repo::Git.from_path}, which creates a 
# 
class Git
  
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
  def self.from_path path
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
    closest_dir.chdir do
      root_result = Cmds.capture "git rev-parse --show-toplevel"
      
      unless root_result.ok?
        raise QB::FSStateError,
              "Path #{ raw_input_path.inspect } does not appear to be in a " +
              "Git repo (looked in #{ closest_dir.inspect })."
      end
      
      root = Pathname.new root_result.out.chomp
      
      
      
    end # chdir
    
  end # .from_path
  
  
  # Attributes
  # =====================================================================
  
  attr_reader :raw_input_path,
              :root
  
  
  # Constructor
  # =====================================================================
  
  def initialize(
    raw_input_path: nil,
    root:,
    
  )
    @raw_input_path = raw_input_path
    @root = root
  end
  
  
  # Instance Methods
  # =====================================================================
  
  def head
    
  end
  
  # @return [nil, String]
  #   Current branch of the working directory, or `nil` if it's not on any
  #   (detached head state).
  #   
  def branch
    
  end
  
  # @return [Boolean]
  #   True if the working directory is clean (no new file or uncommitted
  #   changes). Figures this out by running a `git status` command in the 
  #   repo root.
  # 
  def clean?
    Cmds.new('git status --porcelain 2>/dev/null', chdir: root).
      chomp!.
      empty?
  end
  
end # class Git

end # module Repo
end # module QB
