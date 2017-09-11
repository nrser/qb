module QB
  # Base class for QB errors.
  class Error < StandardError; end
  
  
  # State Errors
  # =====================================================================
  # 
  # Raised when something - a role, the file system, etc. - is in a state 
  # that we can't deal with.
  # 
  
  # Raised when something is in a bad state and no more specific error 
  # subclass applies.
  class StateError < Error; end
  
  # Raised when a version mismatch occurs.
  class VersionError < StateError; end
  
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
  
  # Raised when the file system is in a state that doesn't work for what we're
  # trying to do.
  class FSStateError < StateError; end
  
  
  # User Input Errors
  # =====================================================================
  # 
  # Raised when we got bad user input.
  # 
  
  # Raised when we got bad user input and no more specific error applies.
  class UserInputError < Error; end
  
end # module QB
