# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

require 'json'
require 'pp'

# Deps
# ----------------------------------------------------------------------------

require 'nrser'


# Project / Package
# -----------------------------------------------------------------------

require 'qb/util/resource'


# Declarations
# =====================================================================

module QB; end
module QB::Ansible; end


# Refinements
# =======================================================================

using NRSER::Types


# Definitions
# =====================================================================

class QB::Ansible::Module < QB::Util::Resource
  
  # Sub-Tree Requirements
  # ============================================================================

  require_relative './module/response'
  
  
  # Mixins
  # ============================================================================
  
  include NRSER::Log::Mixin
  
  
  # Class Methods
  # =====================================================================
  
  # @todo Document setup_logging method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.setup_logging!
    if ENV['QB_STDIO_ERR']
      $stderr = UNIXSocket.new ENV['QB_STDIO_ERR']
    end
    
    if ENV['QB_STDIO_OUT']
      $stdout = UNIXSocket.new ENV['QB_STDIO_OUT']
    end
    
    if ENV['QB_STDIO_IN']
      $stdin = UNIXSocket.new ENV['QB_STDIO_IN']
    end
    
    if $stderr.is_a?( UNIXSocket )
      NRSER::Log.setup! application: 'qb', dest: $stderr
      
      [
        ['in', $stdin],
        ['out', $stdout],
        ['err', $stderr],
      ].each do |name, io|
        if io.is_a? UNIXSocket
          env_var_name = "QB_STDIO_#{ name.upcase }"
          logger.trace "Connected to QB process std#{ name } stream",
            env_var_name => ENV[env_var_name],
            path: io.path
        end
      end
    end
  end # .setup_logging
  
  
  # Is the module being run from Ansible via it's "WANT_JSON" mode?
  # 
  # Tests if `argv` is a single string argument that is a file path.
  # 
  # @see http://docs.ansible.com/ansible/latest/dev_guide/developing_program_flow_modules.html#non-native-want-json-modules
  # 
  # @param [Array<String>] argv
  #   The CLI argument strings.
  # 
  # @return [Boolean]
  #   `true` if `argv` looks like it came from Ansible's "WANT_JSON" mode.
  # 
  def self.want_json_mode? argv = ARGV
    ARGV.length == 1 && File.file?( ARGV[0] )
  end # .want_json_mode?
  
  
  # @todo Document run! method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.run!
    setup_logging!
    
    if want_json_mode?
      run_from_json_args_file! ARGV[0]
    else
      run_from_cli_options!
    end
  end # .run!
  
  
  # Create and run an instance and populate it's args by loading JSON from a
  # file path.
  # 
  # Used to run via Ansible's "WANT_JSON" mode.
  # 
  # @see http://docs.ansible.com/ansible/latest/dev_guide/developing_program_flow_modules.html#non-native-want-json-modules
  # 
  # @param [String | Pathname] file_path
  #   Path to the JSON file containing the args.
  # 
  # @return (see #run!)
  # 
  def self.run_from_json_args_file! file_path
    file_contents = File.read file_path
    
    args = JSON.load file_contents
    
    t.hash_( keys: t.str ).check( args ) do |type:, value:|
      binding.erb <<~END
        JSON file contents must load into a `Hash<String, *>`
        
        Loaded value (of class <%= value.class %>):
        
            <%= value.pretty_inspect %>
        
      END
    end
    
    run_from_args!  args,
                    args_source: {
                      type: :file,
                      path: file_path,
                      contents: file_contents,
                    }
  end # .run_from_json_args_file!
  
  
  # Run from a hash-like of argument names mapped to values, with optional
  # info about the source of the arguments.
  # 
  # @param [#each_pair] args
  #   Argument names (String or Symbol) mapped to their value data.
  # 
  # @return (see #run!)
  # 
  def self.run_from_args! args, args_source: nil
    instance = self.from_data args
    instance.args_source = args_source
    instance.run!
  end # .run_from_args!
  
  
  # Alias for defining args as props
  
  # @todo Document arg method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.arg *args, &block
    prop *args, &block
  end # .arg
  
  
  # Attributes
  # ==========================================================================
  
  # Optional information on the source of the arguments.
  # 
  # @return [nil | Hash<Symbol, Object>]
  #     
  attr_accessor :args_source
  
  
  # Construction
  # =====================================================================
  
  def initialize values = {}
    super values
    
    @changed = false
    # init_set_args!
    
    @facts = {}
    @warnings = []
    
    @qb_stdio_out = nil
    @qb_stdio_err = nil
    @qb_stdio_in = nil
    
    logger.info "ARGV", argv: ARGV
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
  
  
  def run!
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
              ansible_facts: @facts.stringify_keys,
              warnings: @warnings
  end
  
  def exit_json hash
    # print JSON response to process' actual STDOUT (instead of $stdout,
    # which may be pointing to the qb parent process)
    STDOUT.print JSON.pretty_generate(hash.stringify_keys)
    
    [
      [:stdin, $stdin],
      [:stdout, $stdout],
      [:stderr, $stderr],
    ].each do |name, socket|
      if socket && socket.is_a?( UNIXSocket )
        logger.trace "Flushing socket #{ name }."
        socket.flush
        logger.debug "Closing #{ name } socket at #{ socket.path.to_s }."
        socket.close
      end
    end
    
    exit 0
  end
  
  def fail msg
    exit_json failed: true, msg: msg, warnings: @warnings
  end
end # class QB::Ansible::Module
