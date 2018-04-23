module QB; end
module QB::Ansible; end


# @todo document QB::Ansible::Env class.
class QB::Ansible::Env
  
  # Constants
  # ======================================================================
  
  VAR_NAME_PREFIX = 'ANSIBLE'
  
  
  # Class Methods
  # ======================================================================
  
  
  # @todo Document to_var_name method.
  # 
  # @param [type] name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.to_var_name name
    "#{ VAR_NAME_PREFIX }_#{ name.to_s.upcase }"
  end # .to_var_name
  
  
  
  # Instance Attributes
  # ======================================================================
  
  
  # @!attribute [r] roles_path
  #   @return [Array<Pathname>]
  attr_reader :roles_path
  
  
  # @!attribute [r] library
  #   @return [Array<Pathname>]
  attr_reader :library
  
  
  # @!attribute [r] filter_plugins
  #   @return [Array<Pathname>]
  attr_reader :filter_plugins
  
  
  # Paths to search for Ansible/Jinja2 "Lookup Plugins"
  # 
  # @return [Array<Pathname>]
  # 
  attr_reader :lookup_plugins
  
  
  # Paths to search for Ansible/Jinja2 "Test Plugins"
  # 
  # @return [Array<Pathname>]
  # 
  attr_reader :test_plugins
  
  
  attr_reader :python_path
  
  
  # `ANSIBLE_CONFIG_<name>=<value>` ENV var values.
  # 
  # @see http://docs.ansible.com/ansible/latest/intro_configuration.html
  # 
  # @return [Hash<(String | Symbol), String]
  #     
  attr_reader :config
  
  
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `QB::Ansible::Env`.
  def initialize
    # NOTE  this includes role paths pulled from a call-site local
    #       ansible.cfg
    @roles_path = QB::Role.search_path. # since QB::Role.search_path is an Array
      select(&:directory?).
      map(&:realpath). # so uniq works
      uniq # drop dups (seems to keep first instance so preserves priority)
    
    @library = [
      QB::ROOT.join('library'),
    ]
    
    @filter_plugins = [
      QB::ROOT.join('plugins', 'filter'),
    ]
    
    @lookup_plugins = [
      QB::ROOT.join('plugins', 'lookup'),
    ]
    
    @test_plugins = [
      QB::ROOT.join( 'plugins', 'test' ),
    ]
    
    @python_path = [
      QB::ROOT.join( 'lib', 'python' ),
      *(ENV['PYTHONPATH'] || '').split( ':' ),
    ]
    
    @config = {}
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  # @todo Document to_h method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.''
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def to_h
    hash = [
      :roles_path,
      :library,
      :filter_plugins,
      :lookup_plugins,
      :test_plugins,
    ].map { |name|
      value = self.send name
      
      value = value.join(':') if value.is_a?(Array)
      
      [self.class.to_var_name(name), value]
    }.to_h
    
    config.each { |name, value|
      hash[ self.class.to_var_name( "CONFIG_#{ name }" ) ] = value.to_s
    }
    
    hash[ 'QB_AM_AUTORUN_PATH' ] = \
      (QB::ROOT / 'load' / 'ansible' / 'module' / 'autorun.rb').to_s
    
    hash[ 'QB_AM_SCRIPT_PATH' ] = \
      (QB::ROOT / 'load' / 'ansible' / 'module' / 'script.rb').to_s
    
    hash[ 'PYTHONPATH' ] = python_path.join ':'
    
    hash
  end # #to_h
  
  
end # class QB::Ansible::Env

require 'qb/ansible/env/devel'
