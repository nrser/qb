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
require 'nrser/props/immutable/instance_variables'

# Project / Package
# -----------------------------------------------------------------------

require 'qb/ipc/stdio/client'


# Declarations
# =====================================================================

module QB; end
module QB::Ansible; end


# Refinements
# =======================================================================

using NRSER::Types


# Definitions
# =====================================================================

module QB
module Ansible
class QB::Ansible::Module
  
  # Sub-Tree Requirements
  # ============================================================================

  require_relative './module/response'
  
  
  # Mixins
  # ============================================================================
  
  include NRSER::Props::Immutable::InstanceVariables
  
  include NRSER::Log::Mixin
  
  
  # Class Methods
  # =====================================================================
  
  module Formatters
    class Processor < SemanticLogger::Formatters::Default
      
      def backtrace_to_s
        lines = log.backtrace_to_s.lines
        
        if lines.length > 42
          lines = [
            *lines[0..21],
            "\n# ...\n\n",
            *lines[-21..-1]
          ]
        end
        
        lines.join
      end
      
      # Exception
      def exception
        "-- Exception: #{log.exception.class}: #{log.exception.message}\n#{backtrace_to_s}" if log.exception
      end
    end
    
    class JSON < SemanticLogger::Formatters::Raw
      # Default JSON time format is ISO8601
      def initialize  time_format: :iso_8601,
                      log_host: true,
                      log_application: true,
                      time_key: :timestamp
        super(
          time_format: time_format,
          log_host: log_host,
          log_application: log_application,
          time_key: time_key,
        )
      end
      
      def call log, logger
        raw = super( log, logger )
        
        begin
          raw.to_json
        rescue Exception => error
          # SemanticLogger::Processor.instance.appender.logger.warn \
          #   "Unable to JSON encode for logging", raw: raw
          
          $stderr.puts "Unable to JSON encode log"
          $stderr.puts raw.pretty_inspect
          
          raise
        end
      end
    end
  end
  
  
  def self.setup_io!
    # Initialize
    $qb_stdio_client ||= QB::IPC::STDIO::Client.new.connect!
    
    if $qb_stdio_client.log.connected? && NRSER::Log.appender.nil?
      # SemanticLogger::Processor.logger = \
      
      SemanticLogger::Processor.instance.appender.logger = \
        SemanticLogger::Appender::File.new(
          io: $stderr,
          level: :warn,
          formatter: Formatters::Processor.new,
        )
      
      NRSER::Log.setup! \
        application: 'qb',
        sync: true,
        dest: {
          io: $qb_stdio_client.log.socket,
          formatter: Formatters::JSON.new,
        }
    end
    
  end # .setup_logging
  
  
  # Wrap a "run" call with error handling.
  # 
  # @private
  # 
  # @param [Proc<() => RESULT] &block
  # 
  # @return [RESULT]
  #   On success, returns the result of `&block`.
  # 
  # @raise [SystemExit]
  #   Any exception raised in `&block` is logged at `fatal` level, then
  #   `exit false` is called, raising a {SystemExit} error.
  #   
  #   The only exception: if `&block` raises a {SystemExit} error, that error
  #   is simply re-raised without any logging. This should allow nesting
  #   {.handle_run_error} calls, since the first `rescue` will log any
  #   error and raise {SystemExit}, which will then simply be bubbled-up
  #   by {.handle_run_error} wrappers further up the call chain.
  # 
  def self.handle_run_error &block
    begin
      block.call
    rescue SystemExit => error
      # Bubble {SystemExit} up to exit normally
      raise
    rescue Exception => error
      # Everything else is unexpected, and needs to be logged in a way that's
      # more useful than the JSON-ified crap Ansible would normally print
      
      # If we don't have a logger setup, log to real `STDERR` so we get
      # *something* back in the Ansible output, even if it's JSON mess
      if NRSER::Log.appender.nil?
        NRSER::Log.setup! application: 'qb', dest: STDERR
      end
      
      # Log it out
      logger.fatal error
      
      # And GTFO
      exit false
    end
  end # .handle_run_error
  
  private_class_method :handle_run_error
  
  
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
  def self.WANT_JSON_mode? argv = ARGV
    ARGV.length == 1 && File.file?( ARGV[0] )
  end # .WANT_JSON_mode?
  
  
  # Load args from a file in JSON format.
  # 
  # @param [String | Pathname] file_path
  #   File path to load from.
  # 
  # @return [Array<(Hash, Hash?)>]
  #   Tuple of:
  #   
  #   1.  `args:`
  #       -   `Hash<String, *>`
  #   2.  `args_source:`
  #       -   `nil | Hash{ type: :file, path: String, contents: String }`
  # 
  def self.load_args_from_JSON_file file_path
    file_contents = File.read file_path

    args = JSON.load( file_contents ).with_indifferent_access

    t.hash_( keys: t.str ).check( args ) do |type:, value:|
      binding.erb <<~END
        JSON file contents must load into a `Hash<String, *>`
        
        Loaded value (of class <%= value.class %>):
        
            <%= value.pretty_inspect %>
        
      END
    end
    
    [ args, { type: :file,
              path: file_path.to_s,
              contents: file_contents,
            } ]
  end
  
  
  # Load the raw arguments.
  # 
  def self.load_args
    if WANT_JSON_mode?
      load_args_from_JSON_file ARGV[0]
    else
      load_args_from_CLI_options
    end
  end
  
  
  # Run the module!
  # 
  # @return (see #run!)
  # 
  def self.run!
    handle_run_error do
      setup_io!
      
      args, args_source = load_args
      run_from_args! args, args_source: args_source
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
  def self.run_from_JSON_args_file! file_path
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
  end # .run_from_JSON_args_file!
  
  
  # Run from a hash-like of argument names mapped to values, with optional
  # info about the source of the arguments.
  # 
  # @param [#each_pair] args
  #   Argument names (String or Symbol) mapped to their value data.
  # 
  # @return (see #run!)
  # 
  def self.run_from_args! args, args_source: nil
    logger.trace "Running from args",
      args: args,
      args_source: args_source
    
    instance = self.from_data args
    instance.args_source = args_source
    instance.args = args
    instance.run!
  end # .run_from_args!
  
  
  # @todo Document arg method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.arg *args, **opts
    name, opts = t.match args.length,
      # Normal {.prop} form
      1, ->( _ ){ [ args[0], opts ] },
      
      # Backwards-compatible form
      2, ->( _ ){ [ args[0], opts.merge( type: args[1] ) ]  }
    
    prop name, **opts
  end # .arg
  
  
  # Attributes
  # ==========================================================================
  
  # Optional information on the source of the arguments.
  # 
  # @return [nil | Hash<Symbol, Object>]
  #     
  attr_accessor :args_source
  
  
  # The raw parsed arguments. Used for backwards-compatibility with how
  # {QB::Ansible::Module} used to work before {NRSER::Props} and {#arg}.
  # 
  # @todo
  #   May want to get rid of this once using props is totally flushed out.
  #   
  #   It should at least be deal with in the constructor somehow so this
  #   can be changed to an `attr_reader`.
  # 
  # @return [Hash<String, VALUE>]
  #     
  attr_accessor :args
  
  
  # The response that will be returned to Ansible (JSON-encoded and written
  # to `STDOUT`).
  # 
  # @return [QB::Ansible::Module::Response]
  #     
  attr_reader :response
  
  
  # Construction
  # =====================================================================
  
  def initialize values = {}
    initialize_props values
    @response = QB::Ansible::Module::Response.new
  end
  
  
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
  # QB::IPC::STDIO for details and implementation).
  # 
  # We use those channels if present to provide logging mechanisms.
  # 
  
  # Forward args to {QB.debug} if we are connected to a QB STDERR stream
  # (write to STDERR).
  # 
  # @param args see QB.debug
  # 
  def debug *args
    logger.debug payload: args
  end
  
  
  # Old logging function - use `#logger.info` instead.
  # 
  # @deprecated
  # 
  def info msg
    logger.info msg
  end
  
  
  # Append a warning message to the {#response}'s {Response#warnings}
  # array and log it.
  # 
  # @todo
  #   Should be incorporated into {#logger}? Seems like it would need one of:
  #   
  #   1.  `on_...` hooks, like `Logger#on_warn`, etc.
  #       
  #       This might be nice but I'd rather hold off on throwing more shit
  #       into {NRSER::Log::Logger} for the time being if possible.
  #       
  #   2.  Adding a custom appender when we run a module that has a ref to
  #       the module instance and so it's {Response}.
  #       
  # 
  # @param [String] msg
  #   Non-empty string.
  # 
  # @return [nil]
  # 
  def warn msg
    logger.warn msg
    response.warnings << msg
    nil
  end
  
  
  def run!
    result = main
    
    case result
    when nil
      # pass
    when Hash
      response.facts.merge! result
    else
      raise "result of #main should be nil or Hash, found #{ result.inspect }"
    end
    
    done
  end
  
  
  def changed! facts = {}
    response.changed = true
    
    unless facts.empty?
      response.facts.merge! facts
    end
    
    done
  end
  
  
  def done
    exit_json response.to_data( add_class: false ).compact
  end
  
  
  def exit_json hash
    # print JSON response to process' actual STDOUT (instead of $stdout,
    # which may be pointing to the qb parent process)
    STDOUT.print JSON.pretty_generate( hash.stringify_keys )
    
    exit true
  end
  
  
  def fail msg, **values
    fail_response = QB::Ansible::Module::Response.new \
      failed: true,
      msg: msg.to_s,
      warnings: response.warnings,
      depreciations: response.depreciations
    
    STDOUT.print \
      JSON.pretty_generate( fail_response.to_data( add_class: false ).compact )
    
    exit false
  end
  
end; end; end # class QB::Ansible::Module
