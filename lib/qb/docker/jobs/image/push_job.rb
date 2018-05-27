# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------
require 'resque-retry'
require 'resque-lock-timeout'

# Project / Package
# -----------------------------------------------------------------------

require 'qb/docker/cli'
require 'qb/jobs'


# Refinements
# =======================================================================


# Namespace
# =======================================================================

module  QB
module  Docker
module  Jobs
module  Image


# Definitions
# =======================================================================

# @todo document PushJob class.
class PushJob < QB::Jobs::Job
  
  # Mixins
  # ========================================================================
  
  # # Add retry support
  # extend Resque::Plugins::Retry
  # 
  # # Add job ID lock with timeout
  # extend Resque::Plugins::LockTimeout
  
  
  # Config
  # ============================================================================
  
  @queue = 'qb'
  
  # Timeout (in seconds)
  @lock_timeout = 1.hour.to_i
  
  # Retry up to five times, delaying 5 seconds between each
  @retry_limit = 0
  @retry_delay = 5
  
  logger.level = :trace
  
  # Class Methods
  # ========================================================================
  
  # def self.notify_group
  #   @image_name || Process.pid
  # end
  # 
  # 
  # def self.notify_options **options
  #   {
  #     title: "#{ self.name }",
  #     group: notify_group,
  #   }.merge **options
  # end
  # 
  # 
  # def self.notify message, **options, &block
  #   QB::Jobs.notify message, notify_options( **options ), &block
  # end
  
  # Identifier used for the lock, which is the name of the image to push.
  # 
  # @param [String] image_name
  #   The image name that will be provided to `docker push`.
  # 
  # @return [String]
  #   Just returns `image_name`.
  # 
  def identifier image_name
    image_name
  end # .identifier
  
  
  def notify_group
    "#{ self.class.name }<#{ @image_name }>"
  end
  
  
  # Do the push.
  # 
  # @param [String] image_name
  #   The image name that will be provided to `docker push`.
  # 
  # @return [nil]
  # 
  def perform image_name
    @image_name = image_name
    
    logger.notify(
      group: notify_group,
    ).info "PUSHING Docker image #{ image_name }..."
    
    result = QB::Docker::CLI.push image_name
    
    if result.ok?
      notify "Docker image #{ image_name } PUSHED."
      return nil
    end
    
    logger.notify(
      group: notify_group,
    ).error "Pushing #{ image_name } failed:\n#{ result.err }"
    
    result.assert
    
    nil
  end # .perform
  
  
end # class PushJob


# /Namespace
# =======================================================================

end # module Image
end # module Jobs
end # module Docker
end # module QB
