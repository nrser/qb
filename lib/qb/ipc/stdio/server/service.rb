# Requirements
# =====================================================================

# Stdlib
# ----------------------------------------------------------------------------

require 'thread'
require 'socket'
require 'fileutils'

# Deps
# ----------------------------------------------------------------------------

require 'nrser'

# Project
# ----------------------------------------------------------------------------

# Need {QB::IPC::STDIO.path_env_var_name}
require 'qb/ipc/stdio'


# Definitions
# =====================================================================
  
# STDIO as a service exposed on a UNIX socket so that modules can stream
# their output to it, which is in turn printed to the console `qb` is running
# in.
class QB::IPC::STDIO::Server::Service
  
  # Mixins
  # ========================================================================
  
  # Add {.logger} and {#logger}
  include NRSER::Log::Mixin
  
  
  # Attributes
  # ========================================================================
  
  # The service's name, like `:in`, `:out`, `:err`.
  # 
  # @return [Synbol]
  #     
  attr_reader :name
  
  
  # Absolute path to socket file.
  # 
  # @return [Pathname]
  #     
  attr_reader :path
  
  
  # TODO document `thread` attribute.
  # 
  # @return [attr_type]
  #     
  attr_reader :thread
  
  
  # TODO document `env_var_name` attribute.
  # 
  # @return [String]
  #     
  attr_reader :env_var_name
  
  
  # The UNIX socket server.
  # 
  # @return [UNIXServer?]
  #     
  attr_reader :server
  
  
  # The socket we accept from the server.
  # 
  # @return [UNIXSocket]
  #     
  attr_reader :socket
  
  
  # Construction
  # ========================================================================
  
  # Construct an IO service.
  # 
  # @param [Symbol] name
  #   What this service is for... `:in`, `:out`, `:err`...
  #   
  #   Used as the thread name.
  # 
  def initialize name:, socket_dir:
    @name = name
    @thread = nil
    @server = nil
    @socket = nil
    @env_var_name = QB::IPC::STDIO.path_env_var_name name
    
    @path = socket_dir.join "#{ name }.sock"
    
    self.logger = create_logger
    
    logger.debug "Initialized"
  end
  
  
  protected
  # ========================================================================
    
    # Initialize the {#logger}.
    # 
    # @protected
    # @return [nil]
    # 
    def create_logger
      logger = NRSER::Log[ self ]
      
      # HACK
      # 
      # Tracing the IO is *really* noisy and spaghettis up the log output
      # due to the threaded nature of the this beast... which is what you
      # *want* if you're debugging main/module process IO, since it shows
      # you what's happening synchronously, but that's pretty much all you
      # can debug when it's being output.
      # 
      # The `debug`-level output is
      # 
      # For that reason, I quickly threw
      #  
      if ENV['QB_TRACE_STDIO'].truthy?
        logger.level = :trace
      elsif ENV['QB_DEBUG_STDIO'].truthy?
        logger.level = :debug
      else
        logger.level = :info
      end
      
      logger
    end
    
  public # end private *****************************************************
  
  
  # Instance Methods
  # ========================================================================
  
  # @return [String]
  #   a short string describing the instance. Used to set the name for
  #   instance loggers.
  def to_s
    "#<#{ self.class.name } name=#{ name.inspect } path=#{ path.to_s }>"
  end # #to_s
  
  
  def open!
    logger.debug "Opening..."
    
    # make sure env var is not already set (basically just prevents you from
    # accidentally opening two instances with the same name)
    if ENV.key? env_var_name
      raise "env already contains key #{ env_var_name }" \
            "with value #{ ENV[env_var_name] }"
    end
    
    @thread = Thread.new do
      Thread.current.name = name
      logger.trace "thread started."
      
      @server = UNIXServer.new path.to_s
      
      while true do
        @socket = server.accept
        work_in_thread
      end
    end
    
    # set the env key so children can find the socket path
    ENV[env_var_name] = path.to_s
    logger.debug "Set env var",
      env_var_name => ENV[env_var_name]
    
    logger.debug "Service open."
  end # open
  
  
  # We're done here, clean up!
  # 
  # @todo
  #   Not sure how correct this is... fucking threading. *Seems* to work...
  # 
  # @return [nil]
  # 
  def close!
    logger.debug "Closing...",
      socket: socket,
      server: server,
      path_exists: path.exist?,
      thread: thread,
      env_var: {
        env_var_name => ENV[env_var_name],
      }
    
    # Remove the path from the ENV so if we do anything after this the
    # old one isn't hanging around
    ENV.delete env_var_name
    
    # Kill the thread first so that it can't try to do anything else
    thread.kill if thread && thread.alive?
    
    socket.close unless socket.nil?
    @socket = nil
    server.close unless server.nil?
    @server = nil
    FileUtils.rm( path ) if path.exist?
    
    logger.debug "Closed.",
      socket: socket,
      server: server,
      path_exists: path.exist?,
      thread: thread,
      env_var: {
        env_var_name => ENV[env_var_name],
      }
    
    nil
  end # #close!
  
end # QB::IPC::STDIO::Server::Service
