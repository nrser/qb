# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------
require 'yaml'

# Deps
# -----------------------------------------------------------------------
require 'rocketjob'
require 'nrser'

# Project / Package
# -----------------------------------------------------------------------
require_relative './jobs/job'


# Refinements
# =======================================================================


# Namespace
# =======================================================================

module  QB


# Definitions
# =======================================================================

# Job handling, using {RocketJob} at the moment.
# 
module Jobs
  
  
  # Mixins
  # ========================================================================
  
  include NRSER::Log::Mixin
  
  
  # Constants
  # ========================================================================
  
  HOME_DIR = QB::ROOT / 'rocketjob'
  
  CONFIG_DIR = HOME_DIR / 'config'
  
  CONFIG_FILE_PATH = CONFIG_DIR / 'mongoid.yml'
  
  
  # Class Methods
  # ========================================================================
  
  # Get the "environment" for {RocketJob}, which is a Rails-esque string
  # that tells it what config and database to use.
  # 
  # @return ['production' | 'development' | 'test']
  # 
  def self.env
    if QB.testing?
      'test'
    elsif QB.local_dev?
      'development'
    else
      'production'
    end
  end # .env
  
  
  # @todo Document init! method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.load_config!
    logger.debug "Loading config",
      env: env,
      path: CONFIG_FILE_PATH
    RocketJob::Config.load! env, CONFIG_FILE_PATH
    @config_loaded = true
    logger.debug "Config loaded."
  end # .init!
  
  
  
  # @todo Document config_loaded? method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.config_loaded?
    @config_loaded == true
  end # .config_loaded?
  
  
  
  # @todo Document init! method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.init!
    logger.trace ".init! called..."
    
    if config_loaded?
      logger.debug "Already initialized, no-op."
    else
      load_config!
    end
  end # .init!
  
  
end # module Jobs



# /Namespace
# =======================================================================

end # module QB
