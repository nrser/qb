# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------
require 'nrser'

# Load notification support and the {NRSER::Log::Plugins::Notify} log plugin
require 'nrser/notify/setup'

require 'resque'


# Project / Package
# -----------------------------------------------------------------------

require 'qb/version'


# Refinements
# =======================================================================

require 'nrser/refinements/types'
using NRSER::Types


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
  
  
  def self.queue
    'qb'
  end
  
  
  def self.after_fork_prepare_for_job job
    NRSER::Log.setup! dest: $stdout, sync: true, level: :info
    
    logger.level = :trace
    
    logger.trace "Setting up! (in fork)",
      job: job,
      job_class: job.class,
      job_instance_vars: job.instance_variables.assoc_to { |sym|
        job.instance_variable_get sym
      },
      job_payload: job.payload
    
    if job.payload['args'][0]['require_paths']
      here = Pathname.new __dir__
      
      job.payload['args'][0]['require_paths'].each do |path|
        req_rel_path = Pathname.new( path ).relative_path_from( here ).to_s
        
        if req_rel_path.end_with? '.rb'
          req_rel_path = req_rel_path[0...-3]
        end
        
        logger.trace "Requiring path",
          path: path,
          req_rel_path: req_rel_path
        
        require_relative req_rel_path
      end
    end
  end
  
  
  def self.resolve_require_arg job_class, require_arg
    
    t.match require_arg,
      # Used to indicate that no files need be required
      t.false, [],
      
      # Default
      t.nil, -> {
        src_loc = job_class.source_location
        
        if src_loc.file.nil?
          message = <<~END
            Unable to determine source file for class #{ job_class }, it will
            need to already be loaded or autoload for job to run.
            
            You can avoid this warning by passing `require: false`, which
            indicates that no files need be required.
          END
          
          logger.notify.warn message,
            job_class: job_class
          
          []
        else
          [ src_loc.file ]
        end
      },
      
      t.array, require_arg
    
  end # .resolve_require_arg
  
  
  def self.enqueue job_class, args: [], require: nil
    logger.level = :trace
    
    require_paths = resolve_require_arg job_class, require
    
    logger.trace "Enqueuing job...",
      job_class: job_class,
      require_paths: require_paths,
      args: args
      
    result = Resque.enqueue \
      job_class,
      require_paths: require_paths,
      args: args
    
    logger.trace "Job enqueued",
      result: result
    
  end # .enqueue
  
end # module Jobs


# /Namespace
# =======================================================================

end # module QB


# Post-Processing
# ========================================================================

# This is funky 'cause it calls {QB::Jobs.queue_name} at compile time, so
# it seems like it will do best down here.
require_relative './jobs/job'
