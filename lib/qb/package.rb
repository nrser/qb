# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------

require 'qb/util/resource'

require_relative './package/version'


# Refinements
# =======================================================================

using NRSER::Types


# Definitions
# =======================================================================

# Common properties and methods of package resources, aimed at packages
# represented as directories in projects.
# 
class QB::Package < QB::Util::Resource
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
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
  prop  :ref_path, type: t.maybe( t.dir_path )
  
  
  # @!attribute [r] root_path
  #   Absolute path to the gem's root directory.
  #   
  #   @return [Pathname]
  #   
  prop  :root_path, type: t.dir_path
  
  
  # @!attribute [r] version
  #   Version of the package.
  # 
  #   @return [QB::Package::Version]
  # 
  prop  :version, type: QB::Package::Version
  
  
  # @!attribute [r] name
  #   The string name the package goes by.
  # 
  #   @return [String]
  #     Non-empty string.
  # 
  prop  :name, type: t.non_empty_str
  
  
  # @!attribute [r] repo_rel_path
  #   @todo Doc repo_rel_path property...
  #   
  #   @return [PropRubyType]
  #   
  prop  :repo_rel_path,
        type: t.maybe( t.dir_path ),
        source: :repo_rel_path
  
  
  # Constructor
  # =====================================================================
  
  def initialize repo: NRSER::NO_ARG, **props
    @repo = repo
    super **props
  end # #initialize
  
  
  # Instance Methods
  # =====================================================================
  
  # Repository
  # ---------------------------------------------------------------------
  
  # @todo Document repo method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def repo
    if @repo == NRSER::NO_ARG
      @repo = QB::Repo.from_path root_path
    end
    
    @repo
  end # #repo
  
  
  # @return [Boolean]
  #   `true` if {#root_path} is in a repo type we recognize.
  # 
  def in_repo?
    !!repo
  end # #in_repo?
  
  
  # Relative path from the {#repo} root to the {#root_path}.
  # 
  # Used as the version tag prefix (unless it's `.` - when the repo root is
  # the root path).
  # 
  # @return [Pathname]
  #   
  def repo_rel_path
    root_path.relative_path_from( repo.root_path ) if in_repo?
  end
  
  
  # Get the string prefix for tagging versions of this package.
  # 
  # Only makes any sense if the package is in a recognized repo, and will error
  # out if that's not the case.
  # 
  # The most basic prefix is "v" for packages located at the root of the
  # repository.
  # 
  # @example
  #   repo_root = '.'
  #   package_root = repo_root
  #   QB::Package.from_path( package_root ).version_tag_prefix
  #   # => 'v'
  #   # (an actual tag would look like 'v0.1.2')
  # 
  # To support "multi-package" repos - which is a way of dealing with apps that
  # are composed of multiple versioned services without having to create a new
  # submodule for every micro-service - packages that do not share the same
  # root of the repo are prefixed by the relative path from the repo root to
  # the package root.
  # 
  # @example
  #   repo_root = Pathname.new '.'
  #   package_root = repo_root / 'services' / 'some-service'
  #   QB::Package.from_path( package_root ).version_tag_prefix
  #   # => 'services/some-service/v'
  #   # (an actual tag would look like 'services/some-service/v0.1.2')
  # 
  # This creates a unique and intuitive namespace scheme for supporting
  # multiple independent package versions in a single repo, which has proved
  # handy for container-ized apps.
  # 
  # Unless, of course, you change the package's path. Then it will get wonky.
  # We'll burn that bridge when we come to it.
  # 
  # @return [String]
  # 
  def version_tag_prefix
    if root_path == repo.root_path
      'v'
    else
      (repo_rel_path / 'v').to_s
    end
  end # #version_tag_prefix
  
  
  
  # 
  # 
  # @return [String]
  # 
  def version_tag
    version_tag_prefix + version.semver
  end # #version_tag
  
  
  # @todo Document versions method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def versions
    # method body...
  end # #versions
  
  
end # class QB::Package


# Post-Processing
# =======================================================================

require_relative './package/gem'
