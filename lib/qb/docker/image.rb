# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------

require 'qb/data'

require_relative './image/name'
require_relative './image/tag'


# Refinements
# =======================================================================

require 'nrser/refinements/types'
using NRSER::Types


# Definitions
# =======================================================================

# @todo document Docker::Image class.
module  QB
module  Docker
class   Image < QB::Data::Immutable
  
  include NRSER::Log::Mixin
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
  
  
  def self.with_name name, &block
    block.call \
      case name
      when QB::Docker::Image::Name
        name
      when String
        QB::Docker::Image::Name.from_s name
      when Hash
        QB::Docker::Image::Name.from_data name
      else
        raise NRSER::TypeError.new \
          "Not sure what to do with ", name,
          name: name
      end
  end
  
  
  def self.names **opts
    QB::Docker::CLI.image_names **opts
  end
  
  
  def self.run_cmd cmd, stream: true, raise_on_fail: false
    if stream
      if raise_on_fail
        cmd.stream!
      else
        cmd.stream
      end
    else
      cmd.capture.tap { |result|
        if raise_on_fail && result.error?
          raise QB::Docker::CLI::Error.from_result result
        end
      }
    end
  end
  
  
  def self.run_cmd! cmd, stream: true
    run_cmd cmd, stream: stream, raise_on_fail: true
  end
  
  
  def self.build! name:,
                  path:,
                  push: false,
                  tags: [],
                  _cmd_stream: true,
                  **build_opts
    
    cmd = QB::Docker::CLI.build_cmd path, tag: name.to_s, **build_opts
    
    logger.info "building...",
      name: name.to_s,
      path: path,
      push: push,
      _cmd_stream: _cmd_stream,
      cmd: cmd.prepare
    
    result = run_cmd! cmd, stream: _cmd_stream
    
    tags.each do |tag_arg|
      cmd = QB::Docker::CLI.tag_cmd name, tag_arg
      tag = cmd.args[1]
      logger.debug "Tagging #{ name } as #{ tag }",
        tag_arg: tag_arg
      
      result = run_cmd cmd, stream: _cmd_stream
      
      if result.ok?
        logger.info "Tagged #{ name } as #{ tag }.",
          cmd: cmd.last_prepared_cmd
      else
        logger.error "Failed to tag #{ name } as #{ tag }",
          tag_arg: tag_arg,
          cmd: cmd.last_prepared_cmd
      end
    end
    
    QB::Docker::CLI.push( name ) if push
    
    result
  end
  
  
  def self.ensure_present! name:,
      pull: nil,
      build: nil,
      force: false,
      push: false,
      tags: []
    
    name = QB::Docker::Image::Name.from name
    
    if  pull.nil? &&
        name.tag &&
        name.tag.version.is_a?( QB::Package::Version::Leveled )
      pull = !name.tag.version.dev?
    end
    
    logger.info "Ensuring image is present...",
      name: name.to_s,
      pull: pull,
      push: push,
      force: force
    
    if force
      logger.info "Forcing build...",
        name: name.to_s
        
      build! name: name, push: push, tags: tags, **build
      
      return
    end
    
    if name.exists?
      logger.info "Image exists", name: name.to_s
      return
    end
    
    logger.info "Name does NOT exist",
      name: name.to_s
      
    if pull
      logger.info "Attempting to pull...",
        name: name.to_s
      
      return if QB::Docker::CLI.pull?( name )
    end
      
    
    logger.info "Resorting to building...",
      name: name.to_s,
      path: build[:path]
    
    build! name: name, push: push, tags: tags, **build
    
  end # .ensure_present!
  
  
  # Properties
  # ======================================================================
  
  prop :id, type: t.non_empty_str
  
  # prop :repo, type: QB::Docker::Repo
  # 
  # prop :tag, type: QB::Docker::Image::Tag
  
  
  # Instance Methods
  # ======================================================================
  
  
end; end; end # class QB::Docker::Image
