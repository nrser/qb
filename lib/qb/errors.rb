module QB
  # Base class for QB errors.
  class Error < StandardError; end
  
  # Raised when a version mismatch occurs.
  class VersionError < Error; end
  
  # Raised when the current Ansible version doesn't satisfy:
  # 
  # 1.  A role as defined in `<role_dir>/meta/main.yml:min_ansible_version`)
  #     
  # 2.  QB itself as defined in {QB::MIN_ANSIBLE_VERSION}
  # 
  class AnsibleVersionError < VersionError; end
  
  # Raised when the current QB version doesn't satisfy a role as defined
  # in `<role_dir>/meta/qb[.yml]:required_qb_version`).
  class QBVersionError < VersionError; end
end # module QB
