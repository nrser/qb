# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Need {UNIXSocket}
require 'socket'

# Deps
# -----------------------------------------------------------------------

# Need logging
require 'nrser'

# Project / Package
# -----------------------------------------------------------------------

# Need {QB::IPC::STDIO.path_env_var_name}
require 'qb/ipc/stdio'


# Definitions
# =======================================================================

# @todo document QB::IPC::STDIO::Client class.
class QB::IPC::STDIO::Client
  
  # Mixins
  # ========================================================================
  
  # Add {.logger} and {#logger} methods
  include NRSER::Log::Mixin
  
  
  # Classes
  # ============================================================================
  
  # @todo document Connection class.
  class Connection
    
    # Mixins
    # ========================================================================
    
    # Add {.logger} and {#logger} methods
    include NRSER::Log::Mixin
    
    
    # Attributes
    # ========================================================================
    
    # TODO document `name` attribute.
    # 
    # @return [Symbol]
    #     
    attr_reader :name
    
    
    # TODO document `type` attribute.
    # 
    # @return [:in | :out]
    #     
    attr_reader :type
    
    
    # TODO document `path` attribute.
    # 
    # @return [Pathname?]
    #     
    attr_reader :path
    
    
    # TODO document `socket` attribute.
    # 
    # @return [UNIXSocket?]
    #     
    attr_reader :socket
    
    
    # TODO document `global_original` attribute.
    # 
    # @return [attr_type]
    #     
    attr_reader :global_original
    
    
    # TODO document `env_var_name` attribute.
    # 
    # @return [String]
    #     
    attr_reader :env_var_name
    
    
    # Construction
    # ========================================================================
    
    # Instantiate a new `Connection`.
    def initialize name:, type:
      @name = name
      @type = type
      @global_original = nil
      @path = nil
      @socket = nil
      @env_var_name = QB::IPC::STDIO.path_env_var_name name
    end # #initialize
    
    
    # Instance Methods
    # ========================================================================
    
    def connected?
      !!socket
    end
    
    
    def connect!
      if connected?
        raise "#{ inspect } is already connected!"
      end
      
      if get_path!
        @global_original = global_get
        @socket = UNIXSocket.new path.to_s
        global_set! socket
      end
    end
    
    
    def disconnect!
      return unless connected?
      
      logger.debug "Disconnecting...",
        name: name,
        socket: socket,
        global_original: global_original
      
      # Restore the original global and `nil` it out (if we have one)
      if global_original
        global_set! global_original
        @global_original = nil
      end
      
      # Flush the socket if it's an out-bound
      socket.flush if type == :out
      
      # And close and `nil` it
      socket.close
      @socket = nil
    end
    
    
    protected
    # ========================================================================
      
      # Get the socket path from the ENV and set `@path` to it (which may be
      # `nil` if we don't find anything).
      # 
      # @return [Pathname?]
      # 
      def get_path!
        @path = ENV[ env_var_name ]
        @path = path.to_pn if path
        path
      end
      
      
      # Get the IO global (`$stdin`, `$stdout`, `$stderr`) if {#name} lines
      # up for one of those.
      # 
      # @return [IO?]
      # 
      def global_get
        case name
        when :in
          $stdin
        when :out
          $stdout
        when :err
          $stderr
        end
      end # #global_get
      
      
      # Set the IO global (`$stdin`, `$stdout`, `$stderr`) to `value` if
      # {#name} lines up for one of those.
      # 
      # @param [IO] value
      # @return [void]
      # 
      def global_set! value
        case name
        when :in
          $stdin = value
        when :out
          $stdout = value
        when :err
          $stderr = value
        end
      end
      
    public # end protected ***************************************************
    
  end # class Connection
  
  
  # Class Methods
  # ========================================================================
  
  
  # Attributes
  # ========================================================================
  
  # @return [Connection]
  attr_reader :stdin
  
  # @return [Connection]
  attr_reader :stdout
  
  # @return [Connection]
  attr_reader :stderr
  
  # @return [Connection]
  attr_reader :log
  
  
  # Construction
  # ========================================================================
  
  # Instantiate a new `QB::IPC::STDIO::Client`.
  def initialize
    @stdin  = Connection.new name: :in, type: :in
    @stdout = Connection.new name: :out, type: :out
    @stderr = Connection.new name: :err, type: :out
    @log    = Connection.new name: :log, type: :out
  end # #initialize
  
  
  # Instance Methods
  # ========================================================================
  
  # @return [Array<Connection>]
  #   The three {Connection} instances.
  def connections
    [ @stdin, @stdout, @stderr, @log ]
  end # #connections
  
  
  # Attempt to connect the three streams.
  #
  # @return [self]
  # 
  def connect!
    connections.each &:connect!
    self
  end # #start!
  
  
  
  def disconnect!
    connections.each &:disconnect!
    self
  end
  
end # class QB::IPC::STDIO::Client
