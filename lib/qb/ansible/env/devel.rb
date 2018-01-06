module QB; end
module QB::Ansible; end


# @todo document QB::Ansible::Env class.
class QB::Ansible::Env::Devel < QB::Ansible::Env
  ANSIBLE_HOME = QB::ROOT / 'packages' / 'python' / 'ansible'
  
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
    hash = super
    
    hash['ANSIBLE_HOME'] = ANSIBLE_HOME.to_s
    
    hash['PYTHONPATH'] = [
      # (QB::ROOT / 'lib' / 'python'),
      (ANSIBLE_HOME / 'lib'),
      ENV['PYTHONPATH'],
    ].
      compact.
      map( &:to_s ).
      join( ':' )
    
    path = ENV['PATH'].split ':'
    
    path.insert \
      path.find_index { |p| ! p.start_with?( './' ) },
      (ANSIBLE_HOME / 'bin').to_s
    
    hash['PATH'] = path.join ':'
    
    # hash['ANSIBLE_CONNECTION'] = 'local'
    # hash['ANSIBLE_PYTHON_INTERPRETER'] = '/usr/local/bin/python2'
    
    hash
  end # #to_h
  
  
end # class QB::Ansible::Env
