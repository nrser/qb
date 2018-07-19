# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Used to generate a random ID to use in socket file names
require 'securerandom'

# Need {FileUtils.rm_rf}
require 'fileutils'

# Deps
# -----------------------------------------------------------------------

require 'nrser'

# Project / Package
# -----------------------------------------------------------------------



# Declarations
# ========================================================================

module QB::IPC
  module STDIO; end
end


# Definitions
# =======================================================================

# Server functionality to make the master QB process' STDIO streams available
# to external processes, specifically Ansible modules.
# 
# Ansible's handling of STDIO in modules is really not suitable for our use
# case - we want to see what modules and other external process commands
# are doing in real time, much like invoking them in a Bash script.
# 
# This thing is **far** from perfect, but it's been incredibly helpful for a
# simple solution.
# 
# Basically, {OutService} instances are created for `STDOUT` and `STDERR`,
# which each create a {UNIXServer} on a local socket file and spawn a {Thread}
# to listen to it. The socket's path is then made available to the Ansible
# child process via ENV vars, and that process in turn carries those ENV vars
# to it's module child processes, who can then use an instance of the
# corresponding {QB::IPC::STDIO::Client} class to connect to those sockets and
# write output that is passed through to the master QB process' output streams.
# 
# The protocol is simply text line-based, and modules - or any other process -
# written in other languages can easily connect and write as well.
# 
# @note
#   This feature only works for `localhost`. I have no idea what it will do
#   in other cases. It doesn't seem like it should break anything, but remotely
#   executing modules definitely won't be able to connect to the sockets on
#   the host.
# 
# @todo
#   There is also a {InService} for `STDIN`, but it's is pretty experimental /
#   broken at this point. That would be nice to fix in the future so that
#   programs that make use of user interaction work seamlessly through QB.
#   
#   This will probably require using pseudo-TTY streams or whatever mess.
# 
class QB::IPC::STDIO::Server
  
  # Sub-Tree Requirements
  # ========================================================================
  
  require_relative './server/in_service'
  require_relative './server/out_service'
  require_relative './server/log_service'
  
  
  # Mixins
  # ========================================================================
  
  # Add {.logger} and {#logger} methods
  include NRSER::Log::Mixin
  
  
  # Class Methods
  # ========================================================================
  
  # Clean up resources for an instance. Broken out because I was trying to
  # make it run as a finalizer to remove the directory in all cases, but that
  # does not seem to be triggering. Whatever man...
  # 
  # @param [Fixnum] object_id:
  #   The instance's `#object_id`, just for logging purposes.
  # 
  # @param [Array<Service>]
  #   The instance's services, which we will {Service#close!}.
  # 
  # @param [Pathname] socket_dir:
  #   The tmpdir created for the sockets, which we will remove.
  # 
  # @return [nil]
  # 
  def self.clean_up_for object_id:, services:, socket_dir:
    logger.debug "Cleaning up...",
      object_id: object_id,
      socket_dir: socket_dir
    
    services.each do |service|
      logger.catch.warn(
        "Unable to close service",
        service: service,
      ) { service.close! }
    end
        
    FileUtils.rm_rf( socket_dir ) if socket_dir.exist?
    
    logger.debug "Clean!",
      object_id: object_id,
      socket_dir: socket_dir
    
    nil
  end # .finalize
  
  
  # Make a {Proc} to use for finalization.
  # 
  # Needs to be done outside instance scope to doesn't close over the
  # instance.
  # 
  # @param **kwds
  #   Passed to {.clean_up_for}.
  # 
  # @return [Proc<() => nil>]
  #   @todo Document return value.
  # 
  def self.finalizer_for **kwds
    -> {
      logger.debug "Finalizing...", **kwds
      clean_up_for **kwds
      logger.debug "Finalized", **kwds
    }
  end # .finalizer_for
  
  
  # Attributes
  # ========================================================================
  
  # Where the UNIX socket files get put.
  # 
  # @return [Pathname]
  #     
  attr_reader :socket_dir
  
  
  # Construction
  # ========================================================================
  
  # Instantiate a new `QB::IPC::STDIO::Server`.
  # 
  def initialize
    @socket_dir = Dir.mktmpdir( 'qb-ipc-stdio' ).to_pn
    
    @in_service   = QB::IPC::STDIO::Server::InService.new \
                      name: :in,
                      socket_dir: socket_dir,
                      src: $stdin
                      
    @out_service  = QB::IPC::STDIO::Server::OutService.new \
                      name: :out,
                      socket_dir: socket_dir,
                      dest: $stdout
                      
    @err_service  = QB::IPC::STDIO::Server::OutService.new \
                      name: :err,
                      socket_dir: socket_dir,
                      dest: $stderr
    
    @log_service  = QB::IPC::STDIO::Server::LogService.new \
                      name: :log,
                      socket_dir: socket_dir
                      
    ObjectSpace.define_finalizer \
      self,
      self.class.finalizer_for(
        object_id: object_id,
        services: services,
        socket_dir: socket_dir
      )
  end # #initialize
  
  
  # Instance Methods
  # ========================================================================
  
  # @return [Array<(InService, OutService, OutService)>]
  #   Array of in, out and err services.
  # 
  def services
    [ @in_service, @out_service, @err_service, @log_service ]
  end # #services
  
  
  # Start all the {#services} by calling {Service#open!} on them.
  # 
  # @return [self]
  # 
  def start!
    services.each &:open!
    self
  end # #open!
  
  
  # Stop all {#services} by calling {Service#close!} on them and clean up
  # the resources.
  # 
  # @return [self]]
  # 
  def stop!
    self.class.clean_up_for \
      object_id: object_id,
      services: services,
      socket_dir: socket_dir
    self
  end
  
end # class QB::IPC::STDIO::Server
