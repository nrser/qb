# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

require 'rack'
require 'unicorn'

# Project / Package
# -----------------------------------------------------------------------

require 'qb/ipc/rpc'
require 'qb/ansible/plugins/filters'

# Refinements
# =======================================================================


# Namespace
# =======================================================================

module  QB
module  IPC
module  RPC

# Definitions
# =======================================================================


# @todo document Server class.
class Server

  # Mixins
  # ========================================================================

  include NRSER::Log::Mixin

  # logger.level = :trace


  # Constants
  # ========================================================================

  CONTENT_TYPE_JSON = { 'Content-Type' => 'application/json' }.freeze

  
  # Class Methods
  # ========================================================================

  
  # @todo Document instance method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.instance
    @instance
  end # .instance
  
  # @todo Document run! method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.run_around &block
    unless ENV[QB::IPC::RPC::ENV_VAR_NAME].to_s == ''
      raise NRSER::ConflictError.new \
        "RPC ENV var already set",
        var_name:   QB::IPC::RPC::ENV_VAR_NAME,
        var_value:  ENV[QB::IPC::RPC::ENV_VAR_NAME]
    end

    @instance = new.start!

    ENV[QB::IPC::RPC::ENV_VAR_NAME] = instance.socket_path.to_s

    begin
      block_result = block.call
    ensure
      instance.stop!
      @instance = nil
      ENV.delete QB::IPC::RPC::ENV_VAR_NAME
    end

    block_result
  end # .run_around


  # Attributes
  # ========================================================================
  
  # Temp dir where the socket goes.
  # 
  # @return [Pathname]
  #     
  attr_reader :socket_dir

  
  # Absolute path to the socket file.
  # 
  # @return [Pathname]
  #     
  attr_reader :socket_path


  # TODO document `http_server` attribute.
  # 
  # @return [Unicorn::HTTPServer]
  #     
  attr_reader :http_server

  
  # Construction
  # ========================================================================
  
  # Instantiate a new `Server`, which wraps a {::Unicorn::HttpServer} instance.
  # 
  # @param [::Symbol] unicorn_log_level
  #   Log level for the Unicorn HTTP server. Defaults to `:warn` so that we 
  #   don't see it's info log in `qb` `STDOUT`.
  # 
  def initialize unicorn_log_level: :warn
    @socket_dir = Dir.mktmpdir( 'qb-ipc-rpc' ).to_pn
    @socket_path = socket_dir + 'socket'
    
    unicorn_logger = NRSER::Log[ "#{ self.class.name }#http_server" ]
    unicorn_logger.level = unicorn_log_level
    
    @http_server = ::Unicorn::HttpServer.new self,
      listeners: socket_path.to_s,
      logger: unicorn_logger
  end # #initialize
  
  
  # Instance Methods
  # ========================================================================
  
  def start!
    http_server.start
    self
  end


  def stop! graceful: true
    http_server.stop graceful
    self
  end


  def respond code, values = {}
    [
      code.to_s,
      CONTENT_TYPE_JSON,
      [ values.to_json ]
  ].tap { |response|
    logger.trace "Responding",
      response: response
  }
  end


  def respond_ok values = {}
    respond 200, values
  end


  def respond_error code: 500, message: 'Server error'
    respond code, message: message
  end


  def respond_not_found message: 'Not found'
    respond 404, message: message
  end


  def route path, payload
    case path
    when '/send'
      handle_send payload
    when '/plugins/filters'
      handle_plugins_filters
    else
      respond_not_found
    end
  end


  def handle_plugins_filters
    map = {}
    
    QB::Ansible::Plugins::Filters.methods( false ).each { |method|
      map[method] = {
        receiver: 'QB::Ansible::Plugins::Filters',
        method:   method.to_s,
      }
    }
    
    respond_ok data: map
  end


  def handle_send payload
    receiver = payload.fetch 'receiver'
    method = payload.fetch 'method'
    args = payload.fetch 'args', []

    if payload['kwds'] && !payload['kwds'].empty?
      args = [*args, payload['kwds'].to_options]
    end

    logger.trace "Unpacked /send payload",
      receiver: receiver,
      method: method,
      args: args

    if  Hash === receiver &&
        receiver.key?( NRSER::Props::DEFAULT_CLASS_KEY )
      
      logger.trace "Loading payload into a " + 
        "#{ receiver[NRSER::Props::DEFAULT_CLASS_KEY] }..."

      receiver = NRSER::Props.UNSAFE_load_instance_from_data receiver
    elsif   String === receiver &&
            receiver =~ /\A(?:(?:\:\:)?[A-Z]\w*)+\z/
      if (const = receiver.to_const)
        receiver = const
      end
    end

    logger.trace "Sending...",
      receiver: receiver,
      method: method,
      args: args

    # For some reason this doesn't work:
    # result = receiver.send method, *args, **kwds
    # 
    # So we do this (after conditionally appending kwds up top)
    result = receiver.send method, *args

    logger.trace "Got result, responding",
      result: result

    respond_ok data: result
  end


  def call env
    begin
      request = Rack::Request.new env
      body = request.body.read
      payload = JSON.load body

      logger.trace "Received request",
        path: request.path,
        body: body,
        payload: payload
      
      route request.path, payload
      
    rescue StandardError => error
      logger.error "Error processing request",
        { request: request },
        error
      
      respond_error message: error.message
    end
  end
  
end # class Server


# /Namespace
# =======================================================================

end # module RPC
end # module IPC
end # module QB
