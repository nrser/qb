module QB; end
module QB::Ansible; end


# @todo document QB::Ansible::Env class.
class QB::Ansible::Env < Hash
  
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
    "#{ VAR_NAME_PREFIX }_ #{ name.to_s.upcase }"
  end # .to_var_name
  
  
  
  # Attributes
  # ======================================================================
  
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `QB::Ansible::Env`.
  def initialize
    
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  
end # class QB::Ansible::Env
