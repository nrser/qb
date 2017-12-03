require 'nrser/refinements'

using NRSER

module QB 
module Util 

module Interop
  include SemanticLogger::Loggable
  
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
      logger.debug "Starting #receive..."
      
      # method body
      yaml = $stdin.read
      
      payload = YAML.load yaml
      
      logger.debug "Parsed",
        payload: payload
      
      data = payload.fetch 'data'
      method = payload.fetch 'method'
      args = payload['args'] || []
      kwds = payload['kwds'] || {}
      args << kwds.symbolize_keys unless kwds.empty?
      
      obj = if  data.is_a?( Hash ) &&
                data.key?( NRSER::Meta::Props::DEFAULT_CLASS_KEY )
        NRSER::Meta::Props.UNSAFE_load_instance_from_data data
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
