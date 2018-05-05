# frozen_string_literal: true

# Requirements
# =======================================================================

# deps
require 'nrser'

# package
require_relative './cli/help'
require_relative './cli/play'
require_relative './cli/run'
require_relative './cli/setup'
require_relative './cli/list'


# Definitions
# =======================================================================

module QB
module CLI
  
  
  # Constants
  # ============================================================================
  
  # CLI args that common to all commands that enable debug output
  # 
  # @return [Array<String>]
  # 
  DEBUG_ARGS = ['-D', '--DEBUG'].freeze
  
  
  # Default terminal line width to use if we can't figure it out dynamically.
  # 
  # @return [Fixnum]
  # 
  DEFAULT_TERMINAL_WIDTH = 80
  
  
  # Mixins
  # ============================================================================
  
  # Add {.logger} and {#logger} methods
  include NRSER::Log::Mixin
  
  
  # Module (Static) Methods
  # ============================================================================
  
  def self.set_debug! args
    if DEBUG_ARGS.any? {|arg| args.include? arg}
      ENV['QB_DEBUG'] = 'true'
      DEBUG_ARGS.each {|arg| args.delete arg}
    end
  end
  

  # @todo Document ask method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.ask name:,
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
    
  end # .ask
  
  
  def self.ask_for_option role:, option:
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
  
  
  def self.ask_for_options role:, options:
    options.select { |opt| opt.value.nil? }.each { |option|
      ask_for_option role: role, option: option
    }
  end # .ask_for_options
  
  
  # Lifted from Thor
  # ----------------------------------------------------------------------------
  # 
  # Who I guess took it from Rake..?
  # 
  # I think I'll move QB to Atli at some point but I wanted these now.
  # 
  
  # This code was copied from Rake, available under MIT-LICENSE
  # Copyright (c) 2003, 2004 Jim Weirich
  def self.terminal_width
    result = if ENV["QB_COLUMNS"]
      ENV["QB_COLUMNS"].to_i
    else
      unix? ? dynamic_width : DEFAULT_TERMINAL_WIDTH
    end
    result < 10 ? DEFAULT_TERMINAL_WIDTH : result
  rescue
    DEFAULT_TERMINAL_WIDTH
  end
  
  
  # Calculate the dynamic width of the terminal
  def self.dynamic_width
    @dynamic_width ||= (dynamic_width_stty.nonzero? || dynamic_width_tput)
  end
  
  
  def self.dynamic_width_stty
    `stty size 2>/dev/null`.split[1].to_i
  end
  
  
  def self.dynamic_width_tput
    `tput cols 2>/dev/null`.to_i
  end
  
  
  def self.unix?
    RUBY_PLATFORM =~ \
      /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i
  end

  
end; end # module QB::CLI
