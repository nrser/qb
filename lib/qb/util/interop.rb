require 'nrser/refinements'

using NRSER

module QB 
module Util 

module Interop
  include SemanticLogger::Loggable
  
  class << self
    
    def send_to_instance data, method_name, *args
      logger.debug "Starting #send_to_instance..."
      
      obj = if  data.is_a?( Hash ) &&
                data.key?( NRSER::Meta::Props::DEFAULT_CLASS_KEY )
        NRSER::Meta::Props.UNSAFE_load_instance_from_data data
      else
        data
      end
      
      obj.send method_name, *args
    end # #send_to_instance
    
    
    # @todo Document receive method.
    # 
    # @param [type] arg_name
    #   @todo Add name param description.
    # 
    # @return [return_type]
    #   @todo Document return value.
    # 
    def send_to_const name, method_name, *args
      logger.debug "Starting #send_to_const..."
      
      const = name.to_const
      
      logger.debug "Found constant", const: const
      
      const.public_send method_name, *args
      
    end # #receive
    
    
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
      
      # data = payload.fetch 'data'
      method = payload.fetch 'method'
      args = payload['args'] || []
      kwds = payload['kwds'] || {}
      args << kwds.symbolize_keys unless kwds.empty?
      
      result = if payload['data']
        send_to_instance payload['data'], method, *args
        
      elsif payload['const']
        send_to_const payload['const'], method, *args
        
      else
        raise ArgumentError.new binding.erb <<-ERB
          Expected payload to have 'data' or 'const' keys, neither found:
          
          Payload:
          
              <%= payload.pretty_inspect %>
          
          Input YAML:
          
              <%= yaml %>
          
        ERB
      end
      
      logger.debug "send succeeded", result: result
      
      yaml = result.to_yaml # don't work: sort_keys: true, use_header: true
      
      logger.debug "writing YAML:\n\n#{ yaml }"
      
      $stdout.write yaml
      
      logger.debug "done."
    end # #receive
    
  end # class << self
end # module Interop

end # module Util
end # module QB
