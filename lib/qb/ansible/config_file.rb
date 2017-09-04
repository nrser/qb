# Requirements
# =====================================================================

# stdlib
require 'ostruct'

# deps
require 'parseconfig'

# project
require 'qb/util'


# Refinements
# =====================================================================

require 'nrser/refinements'
using NRSER


module QB; end
module QB::Ansible; end


# A parse of an `ansible.cfg` file, extending {ParseConfig}.
# 
# We need these to read role path and other Ansible variables so we can setup
# paths correctly.
# 
class QB::Ansible::ConfigFile < ParseConfig
  
  # Sub-Scopes
  # =====================================================================
  
  
  # Wrapper around the Hash from the `[defaults]` group in an Asnible 
  # config file.
  # 
  # Instances are returned from {QB::Ansible::ConfigFile#defaults}.
  # 
  class Defaults < Hash
    
    # Attributes
    # =====================================================================
    
    # @!attribute [r] rel_root
    #   @return [Pathname]
    #     Absolute path to use as root for relative paths.
    attr_reader :rel_root
    
    
    # Constructor
    # =====================================================================
    
    # Instantiate a new `QB::Ansible::ConfigFile`.
    # 
    # @param [#each_pair] source
    #   Source for the keys and values.
    # 
    def initialize source, rel_root:
      super()
      source.each_pair { |k, v| self[k] = v }
      @rel_root = rel_root
    end # #initialize
    
    
    # Instance Methods
    # =====================================================================
    
    # @return [Array<Pathname>]
    #   Array of resolved (absolute) {Pathname} instances parsed from the 
    #   `roles_path` value. Empty array `roles_path` key is missing.
    # 
    def roles_path
      if key? 'roles_path'
        self['roles_path'].
          split(':').
          map { |path| QB::Util.resolve @rel_root, path }
      else
        []
      end
    end # #roles_path
    
  end # class Defaults
  
  
  # Constants
  # =====================================================================
  
  # The "well-known" name we look for.
  FILE_NAME = 'ansible.cfg'
  
  
  # Class Methods
  # =====================================================================
  
  
  # @todo Document path? method.
  # 
  # @param [String, Pathname] file_path
  #   
  # 
  # @return [Boolean]
  #   `true` 
  # 
  def self.file_path? file_path
    File.basename(file_path).to_s == FILE_NAME
  end # .path?
  
  
  # Attributes
  # =====================================================================
  
  # @!attribute [r] rel_root
  #   @return [Pathname]
  #     Absolute path to the directory `ansible.cfg` is in; used as the
  #     root for relative paths found in there.
  attr_reader :rel_root
  
  
  # Constructor
  # =====================================================================
  
  # Instantiate a new `QB::Ansible::ConfigFile`.
  def initialize path
    super path
    @rel_root = QB::Util.resolve(path).dirname
  end # #initialize
  
  
  # Instance Methods
  # =====================================================================
  
  # @todo Document defaults method.
  # 
  # @return [QB::Ansible::ConfigFile::Defaults]
  #   @todo Document return value.
  # 
  def defaults
    Defaults.new (self['defaults'] || {}), rel_root: @rel_root
  end # #defaults
  
  
end # class QB::Ansible::ConfigFile



