require 'json'
require 'pp'


# Refinements
# =======================================================================

using NRSER
using NRSER::Types


# Declarations
# =====================================================================

module QB; end
module QB::Ansible; end


# Definitions
# =====================================================================

class QB::Ansible::Module
  
  # Class Variables
  # =====================================================================
  
  @@arg_types = {}
  
  
  # Class Methods
  # =====================================================================
  
  def self.stringify_keys hash
    hash.map {|k, v| [k.to_s, v]}.to_h
  end
  
  
  def self.arg name, type
    @@arg_types[name.to_sym] = type
  end
  
  
  # Construction
  # =====================================================================
  
  def initialize
    @changed = false
    # @input_file = ARGV[0]
    # @input = File.read @input_file
    # @args = JSON.load @input
    init_set_args!
    
    @facts = {}
    @warnings = []
    
    @qb_stdio_out = nil
    @qb_stdio_err = nil
    @qb_stdio_in = nil
    
    # debug "HERE!"
    # debug ENV
    
    # if QB_STDIO_ env vars are set send stdout and stderr
    # to those sockets to print in the parent process
    
    if ENV['QB_STDIO_ERR']
      @qb_stdio_err = $stderr = UNIXSocket.new ENV['QB_STDIO_ERR']
      
      debug "Connected to QB stderr stream at #{ ENV['QB_STDIO_ERR'] } #{ @qb_stdio_err.path }."
    end
    
    if ENV['QB_STDIO_OUT']
      @qb_stdio_out = $stdout = UNIXSocket.new ENV['QB_STDIO_OUT']
      
      debug "Connected to QB stdout stream at #{ ENV['QB_STDIO_OUT'] }."
    end
    
    if ENV['QB_STDIO_IN']
      @qb_stdio_in = UNIXSocket.new ENV['QB_STDIO_IN']
      
      debug "Connected to QB stdin stream at #{ ENV['QB_STDIO_IN'] }."
    end
    
    @@arg_types.each {|key, type|
      var_name = "@#{ key.to_s }"
      
      unless instance_variable_get(var_name).nil?
        raise ArgumentError.new NRSER.squish <<-END
          an instance variable named #{ var_name } exists
          with value #{ instance_variable_get(var_name).inspect }
        END
      end
      
      value = type.check( @args[key.to_s] ) do |type:, value:|
        all_args = @args
        
        binding.erb <<-END
          Value
          
              <%= value.pretty_inspect %>
          
          for argument <%= key.inspect %> is not valid for type
          
              <%= type %>
          
          Arguments:
          
              <%= all_args.pretty_inspect %>
          
        END
      end
      
      instance_variable_set var_name, value
    }
  end
  
  
  protected
  # ========================================================================
    
  def init_set_args!
    if ARGV.length == 1 && File.file?( ARGV[0] )
      # "Standard" Ansible-invoked mode, where the args written in JSON format
      # to a file and the path is provided as the only CLI argument
      # 
      @input_file = ARGV[0]
      @input = File.read @input_file
      @args = JSON.load @input
      
    else
      # QB-specific "fiddle-mode": if we don't have a single valid file path
      # as CLI arguments, parse the CLI options we have in the common
      # 
      #     `--name=value`
      # 
      # format into the `@args` hash.
      # 
      # This lets us run the module file **directly** from the terminal, which
      # is just a quick and dirty way of flushing things out.
      # 
      @fiddle_mode = true
      @args = {}
      
      ARGV.each do |arg|
        if arg.start_with? '--'
          key, value = arg[2..-1].split( '=', 2 )
          
          @args[key] = begin
            JSON.load value
          rescue
            value
          end
        end
      end
    end
  end # #init_set_args!
    
  # end protected
  public
  
  
  # Instance Methods
  # =====================================================================
  
  # Logging
  # ---------------------------------------------------------------------
  # 
  # Logging is a little weird in Ansible modules... Ansible has facilities
  # for notifying the user about warnings and depreciations, which we will
  # make accessible, but it doesn't seem to have facilities for notices and
  # debugging, which I find very useful.
  # 
  # When run inside of QB (targeting localhost only at the moment, sadly)
  # we expose additional IO channels for STDIN, STDOUT and STDERR through
  # opening unix socket files that the main QB process spawns threads to
  # listen to, and we provide those file paths via environment variables
  # so modules can pick those up and interact with those streams, allowing
  # them to act like regular scripts inside Ansible-world (see
  # QB::Util::STDIO for details and implementation).
  # 
  # We use those channels if present to provide logging mechanisms.
  # 
  
  # Forward args to {QB.debug} if we are connected to a QB STDERR stream
  # (write to STDERR).
  # 
  # @param args see QB.debug
  # 
  def debug *args
    if @qb_stdio_err
      header = "<QB::Ansible::Module #{ self.class.name }>"
      
      if args[0].is_a? String
        header += " " + args.shift
      end
      
      QB.debug header, *args
    end
  end
  
  def info msg
    if @qb_stdio_err
      $stderr.puts msg
    end
  end
  
  # Append a warning message to @warnings.
  def warn msg
    @warnings << msg
  end
  
  
  def run
    result = main
    
    case result
    when nil
      # pass
    when Hash
      @facts.merge! result
    else
      raise "result of #main should be nil or Hash, found #{ result.inspect }"
    end
    
    done
  end
  
  def changed! facts = {}
    @changed = true
    @facts.merge! facts
    done
  end
  
  def done
    exit_json changed: @changed,
              ansible_facts: self.class.stringify_keys(@facts),
              warnings: @warnings
  end
  
  def exit_json hash
    # print JSON response to process' actual STDOUT (instead of $stdout,
    # which may be pointing to the qb parent process)
    STDOUT.print JSON.pretty_generate(self.class.stringify_keys(hash))
    
    [
      [:stdin, @qb_stdio_in],
      [:stdout, @qb_stdio_out],
      [:stderr, @qb_stdio_err],
    ].each do |name, socket|
      if socket
        debug "Flushing socket #{ name }."
        socket.flush
        debug "Closing #{ name } socket at #{ socket.path.to_s }."
        socket.close
      end
    end
    
    exit 0
  end
  
  def fail msg
    exit_json failed: true, msg: msg, warnings: @warnings
  end
end # class QB::Ansible::Module
