require_relative './service'
  
# QB STDIO Service to proxy output from modules back to the main user
# process.
class QB::IPC::STDIO::Server::OutService < QB::IPC::STDIO::Server::Service
  def initialize name:, socket_dir:, dest:
    super name: name, socket_dir: socket_dir
    @dest = dest
  end
  
  def work_in_thread
    while (line = @socket.gets) do
      logger.trace "received line",
        line: line,
        dest: @dest
      
      @dest.puts line
    end
  end
end # InService
