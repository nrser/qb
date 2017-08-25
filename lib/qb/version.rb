module QB
  # Constants
  # =====================================================================
  
  GEM_NAME = 'qb'
  
  VERSION = "0.1.87"
  
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
  
  
  # Check that the Ansible version is not less than {QB::MIN_ANSIBLE_VERSION}.
  # 
  # @raise [QB::AnsibleVersionError]
  #   If the version of Ansible found is less than {QB::MIN_ANSIBLE_VERSION}.
  # 
  def self.check_ansible_version
    out = Cmds.out! 'ansible --version'
    version_str = out[/ansible\ ([\d\.]+)/, 1]
    
    if version_str.nil?
      raise NRSER.dedent <<-END
        could not parse ansible version from `ansible --version` output:
        
        #{ out }
      END
    end
    
    version = Gem::Version.new version_str
    
    if version < QB::MIN_ANSIBLE_VERSION
      raise QB::AnsibleVersionError, NRSER.squish(
        <<-END
          QB #{ QB::VERSION } requires Ansible #{ QB::MIN_ANSIBLE_VERSION },
          found version #{ version_str } at #{ `which ansible` }
        END
      )
    end
  end # .check_ansible_version
  
  
  # If `role` has a {QB::Role#qb_requirement} raise an error if this version of
  # QB doesn't satisfy it.
  # 
  # @raise [QB::QBVersionError]
  #   If this version of QB doesn't satisfy the role's requirements.
  # 
  def self.check_qb_version role
    unless  role.qb_requirement.nil? ||
            role.qb_requirement.satisfied_by?(QB.gem_version)    
      raise QB::QBVersionError, NRSER.squish(
        <<-END
          Role #{ role } requires QB #{ role.qb_requirement }, using QB
          #{ QB.gem_version } from #{ QB::ROOT }.
        END
      )
    end
  end # .check_qb_version
  
  
end # module QB
