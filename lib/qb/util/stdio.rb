require 'thread'
require 'socket'
require 'securerandom'
require 'fileutils'
require 'nrser'

using NRSER

module QB; end
module QB::Util; end

module QB::Util::STDIO
  SOCKET_DIR = Pathname.new('/').join 'tmp', 'qb-stdio'
  
  # STDIO as a service exposed on a UNIX socket so that modules can stream
  # their output to it, which is in turn printed to the console `qb` is running
  # in.
  class Service
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
      
      @debug_header = "#{ name }@#{ @path.to_s }"
    end
    
    def debug *args
      QB.debug "#{ @debug_header }", *args
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
        debug "thread started."
        
        @server = UNIXServer.new @path.to_s
        @socket = @server.accept
        
        work_in_thread
      end
      
      # set the env key so children can find the socket path
      ENV[@env_key] = @path.to_s
      debug "set env var #{ @env_key }=#{ ENV[@env_key] }"
      
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