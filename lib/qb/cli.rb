# Requirements
# =======================================================================

# stdlib

# deps

# package
require_relative './cli/help'
require_relative './cli/play'
require_relative './cli/run'


# Requirements
# =======================================================================

require 'nrser/refinements'
using NRSER


# Declarations
# =======================================================================

module QB; end


# Definitions
# =======================================================================

module QB::CLI
  
  # Eigenclass (Singleton Class)
  # ========================================================================
  # 
  class << self
    
    
    # @todo Document ask method.
    # 
    # @param [type] arg_name
    #   @todo Add name param description.
    # 
    # @return [return_type]
    #   @todo Document return value.
    # 
    def ask name:,
            description: nil,
            type:,
            default: NRSER::NO_ARG
      puts
        
      value = loop do
        
        puts "Enter value for #{ name }"
        
        if description
          puts description.indent
        end
        
        puts "TYPE #{ type.to_s }".indent
        
        if default
          puts "DEFAULT #{ default.to_s }".indent
        end
        
        $stdout.write '> '
        
        value = gets.chomp
        
        QB.debug "User input", value
        
        if value == '' && default != NRSER::NO_ARG
          puts <<-END.dedent
            
            Using default value #{ default.to_s }
            
          END
          
          return default
        end
        
        begin
          type.from_s value
        rescue TypeError => e
          puts <<-END.dedent
            Input value #{ value.inspect } failed to satisfy type
            
                #{ type.to_s }
            
          END
        else
          break value
        end
        
      end # loop
      
      puts "Using value #{ value.inspect }"
      
      return value
      
    end # #ask
    
    
    def ask_for_option role:, option:
      default = if role.defaults.key?(option.var_name)
        role.defaults[option.var_name]
      elsif option.required?
        NRSER::NO_ARG
      else
        nil
      end
      
      ask name: option.name,
          description: option.description,
          default: default
          # type: 
    end
    
    
    def ask_for_options role:, options:
      options.select { |opt| opt.value.nil? }.each { |option|
        ask_for_option role: role, option: option
      }
    end # #ask_for_options
    
    
  end # class << self (Eigenclass)
  
end # module QB::CLI
