# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------
require 'nrser'
require 'resque'


# Project / Package
# -----------------------------------------------------------------------

require 'qb/version'


# Refinements
# =======================================================================


# Namespace
# =======================================================================

module  QB


# Definitions
# =======================================================================

# API for running local jobs via Resque.
# 
module Jobs
  
  # Mixins
  # ========================================================================
  
  include NRSER::Log::Mixin
  
  
  # Class Methods
  # ========================================================================
  
  # Get the Redis key namespace for this installation of QB.
  # 
  # I want multiple QB installations to be able to queue and run jobs on the
  # same system using the same system installation of Redis, so using
  # {QB::ROOT} as the queue name seems like the place to try and start.
  # 
  # @return [String]
  # 
  def self.namespace
    "resque:#{ QB::ROOT }"
  end # .queue_name
  
  
  # def self.redis
  #   @redis ||= Redis.new
  # end
  
  
  def self.queue
    'qb'
  end
  
  
  def self.setup!
    logger.info "Setting up!"
    
    # Resque.redis.namepsace = namespace
    NRSER::Log.setup! dest: $stdout, sync: true, level: :trace
  end
  
  
  def self.enqueue klass, *args
    class_name = klass.name
    load_path = klass.source_location[0]
    
    logger.trace "Enqueuing job...",
      class: klass,
      class_name: class_name,
      load_path: load_path,
      args: args
      
    result = Resque.enqueue self, class_name, load_path, *args
    
    logger.trace "Job enqued",
      result: result
  end
  
  
  def self.perform class_name, class_path, *args
    NRSER::Log.setup! dest: $stdout, sync: true, level: :trace
    
    logger.trace "Performing job...",
      class_name: class_name,
      class_path: class_path,
      args: args
    
    logger.trace "Loading #{ class_path }..."
    load class_path
    logger.trace "Path loaded."
    
    logger.trace "Loading target class..."
    klass = class_name.to_const
    logger.trace "Class loaded", class: klass
    
    logger.trace "Calling #{ class_name }#run!...", args: args
    klass.new.run! *args
    logger.trace "Job done."
  end
  
  
  def self.can_notify?
    lazy_var :@can_notify do
      begin
        require 'terminal-notifier'
      rescue LoadError => error
        false
      else
        true
      end
    end
  end
  
  
  def self.notify *args, &block
    return false unless can_notify?
    
    TerminalNotifier.notify *args, &block
  end
  
end # module Jobs


# /Namespace
# =======================================================================

end # module QB


# Post-Processing
# ========================================================================

# This is funky 'cause it calls {QB::Jobs.queue_name} at compile time, so
# it seems like it will do best down here.
require_relative './jobs/job'
