# frozen_string_literal: true

##
# {QB::Role} methods for dealing with role search path.
# 
# Broken out from the main `//lib/qb/role.rb` file because it was starting to
# get long and unwieldy.
# 
##

# Refinements
# =======================================================================

using NRSER
using NRSER::Types


# Definitions
# =======================================================================

class QB::Role
  
  # Constants
  # =====================================================================

  # "Factory defaults" that {QB::Role::PATH} is initialized to, and what it
  # gets reset to when {QB::Role.reset_path!} is called.
  # 
  # Read the {QB::Role::PATH} docs for details on how QB role paths work.
  # 
  # This value is deeply frozen, and you should not attempt to change it -
  # mess with {QB::Role::PATH} instead.
  # 
  # @return [Array<String>]
  # 
  BUILTIN_PATH = [
    
    # Development Paths
    # =================
    # 
    # These come first because:
    # 
    # 1.  They are working dir-local.
    # 
    # 2.  They should only be present in local development, and should be
    #     capable of overriding roles in other local directories to allow
    #     custom development behavior (the same way `./dev/bin` is put in
    #     front or `./bin`).
    # 
    
    # Role paths declared in ./dev/ansible.cfg, if it exists.
    File.join('.', 'dev', 'ansible.cfg'),
    
    # Roles in ./dev/roles
    File.join('.', 'dev', 'roles'),
    
    
    # Working Directory Paths
    # =======================
    # 
    # Next up, `ansible.cfg` and `roles` directory in the working dir.
    # Makes sense, right?
    # 
    
    # ./ansible.cfg
    File.join('.', 'ansible.cfg'),
    
    # ./roles
    File.join('.', 'roles'),
    
    
    # Working Directory-Local Ansible Directory
    # =========================================
    # 
    # `ansible.cfg` and `roles` in a `./ansible` directory, making a common
    # place to put Ansible stuff in an project accessible when running from
    # the project root.
    # 
    
    # ./ansible/ansible.cfg
    File.join('.', 'ansible', 'ansible.cfg'),
    
    # ./ansible/roles
    File.join('.', 'ansible', 'roles'),
    
    # TODO  Git repo root relative?
    #       Some sort of flag file for a find-up?
    #       System Ansible locations?
    
    
    # QB Gem Role Directories
    # =======================
    # 
    # Last, but far from least, paths provided by the QB Gem to the user's
    # QB role install location and the roles that come built-in to the gem.
    
    QB::USER_ROLES_DIR,
    
    QB::GEM_ROLES_DIR,
  ].freeze


  # Array of string paths to directories to search for roles or paths to
  # `ansible.cfg` files to look for an extract role paths from.
  # 
  # Value is a duplicate of the frozen {QB::Role::BUILTIN_PATH}. You can
  # reset to those values at any time via {QB::Role.reset_path!}.
  # 
  # For the moment at least you can just mutate this value like you would
  # `$LOAD_PATH`:
  # 
  #     QB::Role::PATH.unshift '~/where/some/roles/be'
  #     QB::Role::PATH.unshift '~/my/ansible.cfg'
  # 
  # The paths are searched from first to last.
  # 
  # **WARNING**
  # 
  #   Search is **deep** - don't point this at large directory trees and
  #   expect any sort of reasonable performance (any directory that
  #   contains `node_modules` is usually a terrible idea for instance).
  # 
  # @return [Array<String>]
  # 
  PATH = BUILTIN_PATH.dup
  
  
  # Class Methods
  # ======================================================================
  
  # Reset {QB::Role::PATH} to the original built-in values in
  # {QB::Role::BUILTIN_PATH}.
  # 
  # Created for testing but might be useful elsewhere as well.
  # 
  # @return [Array<String>]
  #   The reset {QB::Role::PATH}.
  # 
  def self.reset_path!
    PATH.clear
    BUILTIN_PATH.each { |path| PATH << path }
    PATH
  end # .reset_path!
  
  
  # Gets the array of paths to search for QB roles based on {QB::Role::PATH}
  # and the working directory at the time it's called.
  # 
  # QB then uses the returned value to figure out what roles are available.
  # 
  # The process:
  # 
  # 1.  Resolve relative paths against the working directory.
  #     
  # 2.  Load up any `ansible.cfg` files on the path and add any `roles_path`
  #     they define where the `ansible.cfg` entry was in {QB::Role::PATH}.
  # 
  # @return [Array<Pathname>]
  #   Directories to search for QB roles.
  # 
  def self.search_path
    QB::Role::PATH.
      map { |path|
        if QB::Ansible::ConfigFile.end_with_config_file?(path)
          if File.file?(path)
            QB::Ansible::ConfigFile.new(path).defaults.roles_path
          end
        else
          QB::Util.resolve path
        end
      }.
      flatten.
      reject(&:nil?)
  end
  
end # class QB::Role
