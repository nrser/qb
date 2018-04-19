require_relative './service'

# QB STDIO Service to proxy interactive user input from the main process
# to modules.
class QB::IPC::STDIO::Server::InService < QB::IPC::STDIO::Server::Service
  def initialize name:, socket_dir:, src:
    super name: name, socket_dir: socket_dir
    @src = src
  end
  
  def work_in_thread
    while (line = @src.gets) do
      @socket.puts line
    end
    
    close!
  end
end # InService
