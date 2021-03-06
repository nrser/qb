# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------
require 'pathname'

# Deps
# -----------------------------------------------------------------------
require 'nrser'
require 'nrser/refinements/types'
require 'nrser/props/immutable/instance_variables'

# Package
# -----------------------------------------------------------------------
require 'qb/repo/git'


# Refinements
# =======================================================================

using NRSER::Types


# Definitions
# =======================================================================

# An extension of {Pathname} that implements the facts we want about paths
# as {NRSER::Meta::Props}.
# 
class QB::Path < Pathname
  
  # Mixins
  # =====================================================================
  
  include NRSER::Props::Immutable::InstanceVariables
  
  
  # Props
  # ======================================================================
  
  # Principle path properties
  # ---------------------------------------------------------------------
  # 
  # Values stored as variables on the instance.
  # 
  
  # The current working directory *relevant* to the path - basically, when
  # and where the instance was created, which may be on a totally different
  # system if the instance was loaded from data.
  # 
  # TODO  Not totally flushed out yet, could imagine a lot of problems and
  #       weirdness, but it seems like we need something like this to make
  #       instances transportable. Issues with relative paths come to mind...
  # 
  prop  :cwd,
        type: t.pathname,
        to_data: :to_s
  
  # The raw path argument used to instantiate the path object.
  # 
  # NOTE  Because we reduce {Pathname} instances to {String} when converting
  #       to data, there is some lossy-ness. I guess it's similar to how
  #       symbols and strings all become strings when run through {JSON}
  #       dump and load.
  # 
  prop  :raw,
        type: t.path,
        to_data: :to_s
  
  
  # Derived path properties
  # ---------------------------------------------------------------------
  # 
  # On-demand values computed via method calls.
  # 
  
  prop  :expanded,
        type: t.path,
        source: ->() { expand_path.to_s }
  
  prop  :exists,
        type: t.bool,
        source: :exist?
  
  prop  :is_expanded,
        type: t.bool,
        source: :expanded?
  
  prop  :is_absolute,
        type: t.bool,
        source: :absolute?
  
  prop  :is_relative,
        type: t.bool,
        source: :relative?
  
  prop  :is_dir,
        type: t.bool,
        source: :directory?
  
  prop  :is_file,
        type: t.bool,
        source: :file?
  
  prop  :is_cwd,
        type: t.bool,
        source: :cwd?
  
  prop  :is_symlink,
        type: t.bool,
        source: :symlink?
  
  prop  :relative,
        type: t.maybe( t.path ),
        source: :relative,
        to_data: :to_s
  
  prop  :realpath,
        type: t.maybe( t.path ),
        source: :try_realpath,
        to_data: :to_s
  
  prop  :is_realpath,
        type: t.bool,
        source: :realpath?
  
  
  # Composed properties
  # ---------------------------------------------------------------------
  # 
  # On-demand values that point to other {NRSER::Meta::Props} instances.
  # 
  
  prop  :git,
        type: QB::Repo::Git,
        source: :git
  
  
  # # Value would be *loadable* via init
  # prop  :packages,
  #       type: t.map( keys: t.sym, values: QB::Package ),
  #       default: ->() { QB::Package.all_from_path self }
  # 
  # 
  # # Value would be ignored by init and re-computed
  # prop  :packages,
  #       type: t.map( keys: t.sym, values: QB::Package ),
  #       source: ->() { QB::Package.all_from_path self },
  #       cache: true
  
  # Constructor
  # ======================================================================
  
  # @overload initialize path
  #   Initialize in the same way as you would a {Pathname}. {#cwd} is set to
  #   the current directory (via {Pathname#getwd}) and the `path` argument is
  #   assigned to {#raw}.
  #   
  #   @param [String | Pathname] path
  #     Target path.
  # 
  # @overload initialize **values
  #   Initialize by invoking {NRSER::Meta::Props#initialize_props}.
  #   
  #   The {#raw} value is passed up to {Pathname#initialize}.
  #   
  #   {#cwd} is accepted in `values`, allowing a re-instantiated object to
  #   "make sense" when the process' current directory may no longer be the
  #   one that data was constructed against.
  #   
  #   {#cwd} defaults to the current directory (via {Pathname.getwd}) if not
  #   provided.
  # 
  # @param **values see {NRSER::Meta::Props#initialize_props}
  #   
  def initialize arg
    case arg
    when Hash
      super arg[:raw]
      initialize_props cwd: Pathname.getwd, **arg
    else
      super arg
      initialize_props raw: arg, cwd: Pathname.getwd
    end
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  # @return [Boolean]
  #   `true` if `self` is equal to {#expand_path}.
  # 
  def expanded?
    self == expand_path
  end
  
  
  # @return [Boolean]
  #   `true` if `self` is equal to {#cwd}.
  # 
  def cwd?
    self == cwd
  end
  
  
  # Relative path from {#cwd} to `self`, if one exists.
  # 
  # @return [QB::Path]
  #   If a relative path from {#cwd} to `self` exists.
  # 
  # @return [nil]
  #   If no relative path from {#cwd} to `self` exists. Can't recall exactly
  #   how this happens, but I guess it can...
  # 
  def relative
    begin
      relative_path_from cwd
    rescue ArgumentError => error
      nil
    end
  end
  
  
  # Like {Pathname#realpath} but returns {nil} instead of raising if there
  # isn't one.
  # 
  # @return [nil]
  #   If there is no real path.
  # 
  # @return [Pathname]
  #   If there is a real path.
  # 
  def try_realpath
    begin
      realpath
    rescue SystemCallError => error
      nil
    end
  end
  
  
  # Is `self` already it's real path?
  # 
  # @return [Boolean]
  #   `true` if `self` and {#try_realpath} are equal.
  # 
  def realpath?
    self == try_realpath
  end # #realpath?
  
  
  # @return [Pathname]
  #   A regular (non-{QB::Path}) {Pathname} version of `self`.
  def path
    Pathname.new self
  end
  
  alias_method :pathname, :path
  
  
  # Composed Sub-Instances
  # ---------------------------------------------------------------------
  
  # {QB::Repo::Git} resource for the Git repo {#path} is in one, or {nil} if
  # it isn't.
  # 
  # @return [QB::Repo::Git]
  #   If {#path} is in a Git repo.
  # 
  # @return [nil]
  #   If {#path} is not in a Git repo.
  # 
  def git
    unless instance_variable_defined? :@git
      @git = QB::Repo::Git.from_path path
    end
    
    @git
  end
  
  
  def gem
    unless instance_variable_defined? :@gem
      @gem = QB::Package::Gem.from_root_path path, repo: git
    end
    
    @gem
  end
  
end # class QB::Path
