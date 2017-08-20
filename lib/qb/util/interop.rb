require 'nrser/refinements'

using NRSER

module QB 
module Util 

module Interop
  class << self
    
    # @todo Document receive method.
    # 
    # @param [type] arg_name
    #   @todo Add name param description.
    # 
    # @return [return_type]
    #   @todo Document return value.
    # 
    def receive      
      # method body
      yaml = $stdin.read
      
      File.open('./receive.log', 'w') { |f|
        f.write yaml
      }
      
      payload = YAML.load yaml
      
      data = payload.fetch 'data'
      method = payload.fetch 'method'
      args = payload['args'] || []
      kwds = payload['kwds'] || {}
      args << kwds.symbolize_keys unless kwds.empty?
      
      obj = if data.is_a?(Hash) && data.key?(NRSER::Meta::Props::CLASS_KEY)
        NRSER::Meta::Props.from_data data
      else
        data
      end
      
      result = obj.send method, *args
      
      $stdout.write result.to_yaml
      
    end # #receive
    
  end # class << self
end # module Interop

end # module Util
end # module QB
