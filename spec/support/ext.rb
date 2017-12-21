# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------

require 'support/ext/qb_role'


# Declarations
# =======================================================================

module Support; end


# Definitions
# =======================================================================

# Global extensions to RSpec.
# 
module Support::Ext
  
  # Mixin for methods that will be available in example groups (inside 
  # `define`/`context` but not in the examples themselves).
  # 
  module ExampleGroup
    
    def describe_qb_role name, &body
      describe_x_type "Role", name,
        type: :qb_role,
        metadata: {
          qb_role_name: name,
        },
        &body
    end
    
  end # module ExampleGroup
  
  
  # Mixin for methods that will be available in examples themselves
  # (inside `it`, `before`, etc.)
  # 
  module Example
    
    def described_qb_role_name
      self.class.metadata[:qb_role_name]
    end
    
  end # module Example
  
end # module Support::Ext


# Post-Processing
# =======================================================================

# Mix the extensions in to RSpec
RSpec.configure do |config|
  config.extend   Support::Ext::ExampleGroup
  config.include  Support::Ext::Example
  
  # Mix in the QB Role ones when `type: :qb_role` metadata is present.
  config.extend   Support::Ext::QBRole::ExampleGroup, type: :qb_role
  config.include  Support::Ext::QBRole::Example, type: :qb_role
  
  # Add a little RSpex type prefix for QB Roles.
  config.x_type_prefixes[:qb_role] = '𝑅'
end

# Mix the ExampleGroup extensions into the top-level so they will be available
# there
include Support::Ext::ExampleGroup
