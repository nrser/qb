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
  
  
  # @!attribute [r] lookup_plugins
  #   @return [Array<Pathname>]
  attr_reader :lookup_plugins
  
  
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
      QB::ROOT.join('plugins', 'filter_plugins'),
    ]
    
    @lookup_plugins = [
      QB::ROOT.join('plugins', 'lookup_plugins'),
    ]
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  # @todo Document to_h method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def to_h
    [
      :roles_path,
      :library,
      :filter_plugins,
      :lookup_plugins
    ].map { |name|
      [self.class.to_var_name(name), self.send(name)]
    }.to_h
  end # #to_h
  
  
end # class QB::Ansible::Env
