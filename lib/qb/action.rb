# Dependencies
# =====================================================================

# Thread-safe Hash.
require 'concurrent'



# Refinements
# =====================================================================

require 'nrser/refinements'
using NRSER

require 'nrser/refinements/types'
using NRSER::Types


module QB; end

# @todo document QB::Action module.
module QB::Action
  
  # Eigenclass (Singleton Class)
  # ========================================================================
  # 
  class << self
    
    # Register a {QB::Action} class as available to frontends.
    # 
    # Uses {QB::Action::Base.key} as the registry key (calls `klass.key`).
    # 
    # @param [Class<QB::Action::Base>] klass
    #   Subclass of {QB::Action::Base} to register.
    # 
    # @return [Boolean]
    #   `true` if the class was added, `false` if it was already there.
    # 
    # @raise [RuntimeError]
    #   If there is already a different class registered with `klass`'s key.
    # 
    def register klass
      registry = self.registry
      
      key = t.str.check klass.key
      
      # Try to set it. This will return `nil` if `key` is present.
      result = registry.put_if_absent(key, klass)
      
      if result.nil?
        # `key` is already set. See what it is...
        current = registry[key]
        
        # If it's the class, we're ok, return false to indicate it was already 
        # registered.
        return false if current == klass
        
        # Otherwise, we have a conflict.
        raise RuntimeError.squish <<-END
          key #{ key.inspect } already occupied by class #{ current }.
        END
      end
      
      # The set succeeded. Indicate it by returning `true`.
      return true
    end # #register
    
    
    
    # Returns all registered action classes in a {Hash} of string `key`
    # to {QB::Action::Base} subclasses.
    # 
    # This hash is a *new*, *frozen* 
    # 
    # @return [Hash<String, Class<QB::Action::Base>]
    # 
    def registered
      hash = {}
      registry.each_pair { |key, klass|
        hash[key] = klass
      }
      hash.freeze
    end # #registered
    
    
    
    # @todo Document find method.
    # 
    # @param [type] arg_name
    #   @todo Add name param description.
    # 
    # @return [return_type]
    #   @todo Document return value.
    # 
    def find key_or_alias
      # TODO implement aliases / fuzzy?
      registry[key_or_alias]
    end # #find
    
    
    
    
    # private
    # ========================================================================
      
      # The actual global registry object reference. Uses {Concurrent::Hash}
      # for thread safety (just as a general good practice for global 
      # collections).
      # 
      # @private
      # 
      # @return [Concurrent::Hash]
      # 
      def registry
        @registry ||= Concurrent::Map.new
      end # #registry
      
    # end private
    
  end # class << self (Eigenclass)
  
  
end # module QB::Action

require_relative './action/run'
require_relative './action/list'

