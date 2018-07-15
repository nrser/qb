require 'fileutils'

# Refinements
# =======================================================================

using NRSER


# Definitions
# =======================================================================

module QB::CLI
  module Dev
    include NRSER::Log::Mixin

    logger.level = :trace

    def self.serve *args
      require 'qb/ipc/rpc/server'

      logger.info "Starting up!", pid: Process.pid

      server = QB::IPC::RPC::Server.new
      server.start!

      logger.info "Got going...",
        pid: Process.pid,
        socket_path: server.socket_path.to_s
      
      QB::ROOT.join( 'tmp', 'dev-server.sock' ).write server.socket_path

      $dying = false

      # Needs to happen *after* starting server 'cause it sets traps when it
      # starts which seem to clobber these...
      [ :QUIT, :TERM, :INT ].each do |sig|
        Signal.trap sig do |sig|
          puts "Trapped #{ sig.inspect }"

          if $dying
            puts "Damn, just couldn't die... sorry."
            exit 1
          end

          $dying = true
        end
      end

      until $dying
        # logger.info "still chuggin' along...",
        #   pid: Process.pid,
        #   socket_path: server.socket_path.to_s
        sleep 1
      end

      # Doesn't work...
      # loop do
      #   begin
      #     logger.info "still chuggin' along...",
      #       pid: Process.pid,
      #       socket_path: server.socket_path.to_s
      #     sleep 3
      #   rescue Interrupt
      #     logger.info "Interrupted! So rude..."
      #     break
      #   end
      # end

      logger.info "Shuttin' 'er down boss...'"

      server.stop!

      FileUtils.rm( QB::ROOT.join( 'tmp', 'dev-server.sock' ) )

      logger.info "Done-zo!"
      
      return 0
    end # .serve


    def self.req 
      require 'net_http_unix'

      socket_path = QB::ROOT.join( 'tmp', 'dev-server.sock' ).read.chomp
      client = NetX::HTTPUnix.new "unix://#{ socket_path }"

      path = "/send"

      params = {
        receiver: 'File',
        method: 'basename',
        args: ['blah.exe', '.exe'],
      }

      headers = { "Content-Type" => "application/json",
                  "Accept" => "application/json" }

      start = Time.now
      rsp = client.post path, params.to_json, headers
      delta = Time.now - start

      logger.trace "Response",
        delta: "#{ (delta * 1000).round }ms",
        code: rsp.code,
        body: rsp.body,
        result: JSON.load( rsp.body )['result']
      
    end
  end

  
  def self.dev cmd, *args
    case cmd
    when 'serve', 'server'
      Dev.serve *args.rest
    when 'req'
      Dev.req *args.rest
    else
      raise "bad .dev subcmd: #{ cmd }"
    end
  end
  
  
end # module QB::CLI
