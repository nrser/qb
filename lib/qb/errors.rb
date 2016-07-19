module QB
  # parent class for all QB-specific errors
  class QBError < StandardError; end
  
  # raised when there's a problem with the role being executed
  class RoleError < QBError; end
  
  # raised when there's a problem with the role definition
  class RoleSytaxError < RoleError; end
  
  # raised when Entity has a problem
  class EntityError < QBError; end
  
  # raised when there's an issue defining a field on a YAMLObj
  class FieldDefError < EntityError; end
  
  # raised when trying to construct an entity with a bad value
  class BadValueError < EntityError; end
end