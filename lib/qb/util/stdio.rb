# Requirements
# =====================================================================

# stdlib
require 'thread'
require 'socket'
require 'securerandom'
require 'fileutils'
require 'nrser'

# Refinements
# =====================================================================

require 'nrser/refinements'
using NRSER


# Declarations
# =====================================================================

module QB; end
module QB::Util; end


# Definitions
# =====================================================================

# Utilities for QB's standard-IO (`stdio`) handling feature.
# 
# Normally, Ansible modules can't really do much with `stdio` - they return 
# results by writing JSON to `stdout`, can't do anything useful with `stdin`,
# and I think things written to `stderr` don't go anywhere useful.
# 
# This makes dealing with logging, error reporting and wrapping executables
# that report useful progress info to `stdout` or `stderr` pretty shitty.
# 
# So, what we do is create streaming sockets for `stdout`, `stderr` and 
# `stdin` in the QB process and write their paths to environment variables,
# which will be available to modules.
# 
# {QB::Ansible::Module} automatically detects these variables and sets up
# `$stdout`, `$stderr` and `$stdin` to point to the sockets, which proxy 
# back to the QB process' `stdio`.
# 
# Of course other modules written in any language can also connect to these
# file sockets in the same manner.
# 
# @note
#   This feature only works for `localhost`. I have no idea what it will do
#   in other cases. It doesn't seem like it should break anything, but remotely
#   executing modules definitely won't be able to connect to the sockets on 
#   the host.
# 
# @todo
#   `stdin` support is pretty experimental / broken at this point. That would
#   be nice to fix in the future so that programs that make use of user 
#   interaction work seamlessly through QB. This will probably require 
#   using pseudo-TTY streams or whatever.
# 
module QB::Util::STDIO
  
  # Constants
  # =====================================================================
  
  SOCKET_DIR = Pathname.new('/').join 'tmp', 'qb-stdio'
  
  # STDIO as a service exposed on a UNIX socket so that modules can stream
  # their output to it, which is in turn printed to the console `qb` is running
  # in.
  class Service
    include SemanticLogger::Loggable
    
    def initialize name
      @name = name
      @thread = nil
      @server = nil
      @socket = nil
      @env_key = "QB_STDIO_#{ name.upcase }"
      
      unless SOCKET_DIR.exist?
        FileUtils.mkdir SOCKET_DIR
      end
      
      @path = SOCKET_DIR.join "#{ name }.#{ SecureRandom.uuid }.sock"
      
      self.logger = SemanticLogger[
        [
          "#{ self.class.name } {",
          "  name: #{ name }",
          "  path: #{ @path.to_s }",
          "}"
        ].join( "\n" )
      ]
      
      logger.debug "Initialized"
    end
    
    def debug *args
      # logger.debug "#{ @debug_header }", args
      logger.debug *args
    end
    
    def open!
      debug "opening..."
      
      # make sure env var is not already set (basically just prevents you from
      # accidentally opening two instances with the same name)
      if ENV.key? @env_key
        raise <<-END.squish
          env already contains key #{ @env_key } with value #{ ENV[@env_key] }
        END
      end
      
      @thread = Thread.new do
        Thread.current.name = @name
        debug "thread started."
        
        @server = UNIXServer.new @path.to_s
        
        while true do
          @socket = @server.accept
          
          work_in_thread
        end
      end
      
      # set the env key so children can find the socket path
      ENV[@env_key] = @path.to_s
      debug "set env var", @env_key => ENV[@env_key]
      
      debug "service open."
    end # open
    
    def close!
      # clean up.
      # 
      # TODO not sure how correct this is...
      # 
      debug "closing..."
      
      @socket.close unless @socket.nil?
      @socket = nil
      @server.close unless @server.nil?
      @server = nil
      FileUtils.rm(@path) if @path.exist?
      @thread.kill unless @thread.nil?
      
      debug "closed."
    end
  end # Service
  
  # QB STDIO Service to proxy output from modules back to the main user 
  # process.
  class OutService < Service
    def initialize name, dest
      super name
      @dest = dest
    end
    
    def work_in_thread
      while (line = @socket.gets) do
        debug "#{ @name } received: #{ line.inspect }"
        @dest.puts line
      end
    end
  end # OutService
  
  # QB STDIO Service to proxy interactive user input from the main process
  # to modules.
  class InService < Service
    def initialize name, src
      super name
      @src = src
    end
    
    def work_in_thread
      while (line = @src.gets) do
        @socket.puts line
      end
      
      close!
    end
  end # InService
end # QB::Util::STDIO