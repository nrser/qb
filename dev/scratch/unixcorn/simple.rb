# One-file version! Much better!

# https://stackoverflow.com/questions/18635008/how-to-init-rack-server-listening-to-a-socket

require 'rack'
require 'unicorn'
# require 'rack/handler'

# class Rack::Handler::Unicorn
#   def self.server_class
#     ::Unicorn::HttpServer
#   end

#   def self.run app, opts
#     server = initialize_server(app, opts, extract_config_file(opts))

#     yield(server) if block_given?

#     server.start.join
#   end

#   def self.extract_config_file opts
#     if opts[:server_config]
#       opts[:server_config]
#     else
#       server_name = name[/::(\w+)$/, 1].downcase
#       puts "server_name: #{ server_name.inspect }"
#       config_path = "#{config_dir(opts)}/config/#{server_name}.rb"
#       config_path if File.exist?(config_path)
#     end
#   end

#   def self.config_dir opts
#     if opts[:config]
#       File.dirname(opts[:config])
#     else
#       '.'
#     end
#   end

#   def self.initialize_server app, opts, config_file
#     listeners = if opts[:Port]
#       "#{opts[:Host]}:#{opts[:Port]}"
#     else
#       File.expand_path opts[:Host], __dir__
#     end

#     server_class.new(app, :listeners   => listeners,
#                           :config_file => config_file)
#   end
# end

# Rack::Handler.register('unicorn', Rack::Handler::Unicorn)

# Rack::Handler.
#   get('unicorn').
#   run(  app,
#         Host: './tmp/sockets/simple.socket' )

app = Proc.new do |env|
  req = Rack::Request.new env

  ['200', {'Content-Type' => 'text/html'}, ['A barebones rack app.']]
end

socket_path = File.expand_path './tmp/sockets/simple.socket', __dir__

# require_relative './app'

server = ::Unicorn::HttpServer.new \
  app,
  listeners: socket_path

server.start # .join

$dieing = false

trap "SIGINT" do
  if $dying
    puts "Damn, just couldn't die..."
    exit 1
  end

  $dying = true
end

trap "SIGTERM" do
  if $dying
    puts "Damn, just couldn't die..."
    exit 1
  end

  $dying = true
end

until $dying do
  puts "still going... PID: #{ Process.pid }"
  sleep 3
end

server.stop
exit true
