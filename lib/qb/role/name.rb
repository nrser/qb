##
# {QB::Role} methods for dealing with role names.
# 
# Broken out from the main `//lib/qb/role.rb` file because it was starting to 
# get long and unwieldy.
# 
##

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------
require 'qb/util'


# Refinements
# =======================================================================

require 'nrser/refinements'
using NRSER


# Declarations
# =======================================================================


# Definitions
# =======================================================================

class QB::Role
  
  # Class Methods
  # ======================================================================
  # 
  # Actual functionality is implemented as static methods so that it can be
  # used in cases where we don't have a {QB::Role} instantiated, especially
  # in roles themselves like `//roles/qb/role` with:
  # 
  #     role_role_name: >-
  #       {{ 'QB::Role' | qb_send_const( 'default_name_for', role_dest ) }}
  #     
  #     role_namespaceless: >-
  #       {{ 'QB::Role' | qb_send_const( 'namespaceless_for', role_role_name ) }}
  # 
  
  
  # Do our best to figure out a role name from a path (that might not exist).
  # 
  # We needs this when we're creating a role.
  # 
  # @param [String | Pathname] path
  #   
  # 
  # @return [String]
  # 
  def self.default_name_for path
    resolved_path = QB::Util.resolve path
    
    # Find the first directory in the search path that contains the path,
    # if any do.
    # 
    # It *could* be in more than one in funky situations like overlapping 
    # search paths or link silliness, but that doesn't matter - we consider 
    # the first place we find it to be the relevant once, since the search
    # path is most-important-first.
    # 
    search_dir = search_path.find { |pathname|
      resolved_path.fnmatch? ( pathname / '**' ).to_s
    }
    
    if search_dir.nil?
      # It's not in any of the search directories
      # 
      # If it has 'roles' as a segment than use what's after the last occurrence
      # of that (unless there isn't anything).
      # 
      segments = resolved_path.to_s.split File::SEPARATOR
      
      if index = segments.rindex( 'roles' )
        name_segs = segments[( index + 1 )..( -1 )]
        
        unless name_segs.empty?
          return File.join name_segs
        end
      end
      
      # Ok, that didn't work... just return the basename I guess...
      return File.basename resolved_path
      
    end
    
    # it's in the search path, return the relative path from the containing
    # search dir to the resolved path (string version of it).
    resolved_path.relative_path_from( search_dir ).to_s

  end # #default_name_for
  
  # Old depreciated name
  singleton_class.send :alias_method, :default_role_name, :default_name_for
  
  
  def self.namespace_for name
    *namespace_segments, last = name.split File::Separator
    
    namespace_segments << last.split('.').first if last.include?('.')
     
    if namespace_segments.empty?
      nil
    else
      File.join *namespace_segments
    end
  end
  
  
  def self.namespaceless_for name
    File.basename( name ).split('.', 2).last
  end
  
  
  # Instance Methods
  # ============================================================================
  
  def namespace
    self.class.namespace_for @name
  end
  
  
  def namespaceless
    self.class.namespaceless_for @name
  end
  
end # class QB::Role
