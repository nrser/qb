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


# Definitions
# =======================================================================

# @todo document QB::Repo class.
class QB::Repo < QB::Util::Resource
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  # Get an instance for whatever repo `path` is in.
  # 
  # @param [String, Pathname] path
  #   A path that may be in a repo.
  # 
  # @return [nil]
  #   If `path` *is not* a part of repo we can recognize (`git` only at the
  #   moment, sorry).
  # 
  # @return [QB::Repo]
  #   If `path` *is* not a part of repo we can recognize.
  # 
  def self.from_path path, git: {}
    QB::Repo::Git.from_path path, **git
  end # .from_path
  
  
  # Instantiate a {QB::Repo} for the repo `path` is in or raise if it's not in
  # any single recognizable repo.
  # 
  # @param path see .from_path
  # @param **opts see .from_path
  # 
  # @return [QB::Repo]
  # 
  # @raise [QB::FSStateError]
  #   If `path` is not in a repo.
  # 
  def self.from_path! path, **opts
    from_path( path, **opts ).tap { |repo|
      if repo.nil?
        raise QB::FSStateError,
              "Path #{ path.inspect } does not appear to be in a repo."
      end
    }
  end # .from_path!
  
  
  # Properties
  # ======================================================================
  
  # @!attribute [r] ref_path
  #   User-provided path value used to construct the resource instance, if any.
  #   
  #   This may not be the same as a root path for the resource, such as with
  #   resource classes that can be constructed from any path *inside* the 
  #   directory, like a {QB::Repo::Git}.
  #   
  #   @return [String | Pathname]
  #     If the resource instance was constructed based on a path argument.
  #   
  #   @return [nil]
  #     If the resource instance was *not* constructed based on a path 
  #     argument.
  #   
  prop  :ref_path, type: t.maybe( t.path )
  
  
  # @!attribute [r] root_path
  #   Absolute path to the gem's root directory.
  #   
  #   @return [Pathname]
  #   
  prop  :root_path, type: t.dir_path
  
  
  # @!attribute [r] name
  #   The string name of the repo.
  # 
  #   @return [String]
  #     Non-empty string.
  # 
  prop  :name, type: t.maybe( t.non_empty_str )
  
  
  # Instance Methods
  # ======================================================================
  
  # @todo Document tags method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [Array<String>]
  # 
  def tags
    raise NotImplementedError
  end # #tags
  
  
end # class QB::Repo


# Post-Processing
# =======================================================================

require 'qb/repo/git'
