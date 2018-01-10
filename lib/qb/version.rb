module QB
  # Constants
  # =====================================================================
  
  GEM_NAME = 'qb'
  
  VERSION = "0.3.15.dev"
  
  MIN_ANSIBLE_VERSION = Gem::Version.new '2.1.2'
  
  
  
  # Class Methods
  # =====================================================================
  
  def self.gemspec
    Gem.loaded_specs[GEM_NAME]
  end
  
  
  # Get the {Gem::Version} parse of {QB::VERSION}.
  # 
  # @return [Gem::Version]
  # 
  def self.gem_version
    Gem::Version.new VERSION
  end
  
  
  # @return [Gem::Version]
  #   the Ansible executable version parsed into a Gem version so we can
  #   compare it.
  # 
  def self.ansible_version
    out = Cmds.out! 'ansible --version'
    version_str = out[/ansible\ ([\d\.]+)/, 1]
    
    if version_str.nil?
      raise NRSER.dedent <<-END
        could not parse ansible version from `ansible --version` output:
        
        #{ out }
      END
    end
    
    Gem::Version.new version_str
  end # .ansible_version
  
  
  # Check that the Ansible version is not less than {QB::MIN_ANSIBLE_VERSION}.
  # 
  # @raise [QB::AnsibleVersionError]
  #   If the version of Ansible found is less than {QB::MIN_ANSIBLE_VERSION}.
  # 
  def self.check_ansible_version
    if ansible_version < QB::MIN_ANSIBLE_VERSION
      raise QB::AnsibleVersionError, NRSER.squish(
        <<-END
          QB #{ QB::VERSION } requires Ansible #{ QB::MIN_ANSIBLE_VERSION },
          found version #{ version_str } at #{ `which ansible` }
        END
      )
    end
  end # .check_ansible_version
  
  
end # module QB
