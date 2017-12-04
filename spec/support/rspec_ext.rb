# Extensions to RSpec.
# 
module RSpecExt
  
  # Mixin for methods that will be available in example groups (inside 
  # `define`/`context` but not in the examples themselves).
  # 
  module ExampleGroup
    
    def describe_qb_role name, &body
      describe_x_type "Role", name,
        type: :qb_role,
        &body
    end
    
  end # module ExampleGroup
  
  
  # Mixin for methods that will be available in examples themselves (inside
  # `scenario` blocks, Capy's version of `it` blocks as far as I can tell).
  # 
  # Most Capybara stuff seems like it should land here.
  # 
  module Example
    
  end # module Example
  
end # module RSpecExt


# Mix the extensions in to RSpec
RSpec.configure do |config|
  config.extend RSpecExt::ExampleGroup
  config.include RSpecExt::Example
  
  config.x_type_prefixes[:qb_role] = '𝑅'
end

include RSpecExt::ExampleGroup
