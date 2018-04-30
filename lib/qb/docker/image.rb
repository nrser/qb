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
  
  
  # @todo Document all method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.parsed
    Cmds.new( 'docker images --format raw' ).
      out!.
      split( "\n\n" ).
      map { |chunk|
        parsed = chunk.lines.map { |line|
          name, _, value = line.chomp.partition ': '
          
          if name == 'created_at'
            value = Time.parse value
          end
          
          [name, value]
        }.to_h
      }
  end # .parsed
  
  
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
  
  
  def self.names
    parsed.map { |parse|
      QB::Docker::Image::Name.from_s \
        parse.values_at( 'repository', 'tag' ).join( ':' )
    }
  end
  
  
  def self.dirty
    names.find_all { |name|
      name.tag.version &&
      name.tag.version.build.last.is_a?( String ) &&
      name.tag.version.build.last.end_with?( '-dirty' )
    }
  end
  
  
  def self.remove! *names
    puts Cmds.new( 'docker rmi <%= *names %>' ).prepare( names: names.map( &:to_s ) )
  end
  
  
  def self.name_exists? name
    !Cmds.
      out!( 'docker images --format raw <%= name %>', name: name.to_s ).
      empty?
  end
  
  
  def self.build  name:,
                  path:,
                  args: {},
                  labels: {},
                  push: false,
                  **opts
    cmd = Cmds.new(
      "docker build . --tag <%= name %> <%= opts %>",
      array_mode: :repeat,
      long_opt_separator: ' ',
      hash_join_string: '=',
      chdir: path,
      kwds: {opts: opts.merge('build-arg' => args), name: name},
    )
    
    logger.info "prepared", cmd.prepare
    
    cmd.stream!
    
    self.push if push
  end
  
  
  def self.docker_inspect name
    with_name name do |name|
      Cmds.new(
        "docker inspect <%= name %>",
      ).out!.thru { |out|
        JSON.load out
      }
    end
  end
  
  
  def self.pull name, force: false
    with_name name do |name|
      if force || names.include?( name )
        logger.info "pulling image", name: name.to_s, force: force
        result = Cmds.new( "docker pull <%= name %>" ).stream name: name.to_s
        name_exists? name
      end
    end
  end
  
  
  def self.push name:, force: false
    with_name name do |name|
      if force || !names.include?( name )
        logger.info "pushing image",
          inc: names.include?( name ),
          name: name.to_s,
          force: force,
          present: names.include?( name )
        
        Cmds.new(
          "docker push <%= name %>"
        ).stream! name: name.to_s
      end
    end
  end
  
  
  def self.ensure name:, pull: nil, build: nil, force: false, push: false
    with_name name do |name_|
      name = name_
      
      if  pull.nil? &&
          name.tag &&
          name.tag.version.is_a?( QB::Package::Version::Leveled )
        pull = !name.tag.version.dev?
      end
      
      logger.info "Ensuring image",
        name: name.to_s,
        pull: pull,
        push: push,
        force: force
      
      if force
        logger.info "Forcing build...",
          name: name.to_s
          
        self.build name: name, **build
        
        if push
          self.push name: name, force: force
        end
        
      else
        if name_exists? name
          logger.info "Image exists", name: name.to_s
          return
          
        else
          logger.info "Name does NOT exist",
            name: name.to_s,
            names: names.map( &:to_s )
          
          logger.info "Attempting to pull...",
            name: name.to_s
            
          if pull && self.pull
            logger.info "Image pulled",
              name: name.to_s
              
            return
            
          else
            logger.info "Resorting to building...",
              name: name.to_s,
              path: build[:path]
            
            self.build name: name, **build
            
            if push
              self.push name: name, force: force
            end
            
          end
        end
      end
    end
  end
  
  
  # Properties
  # ======================================================================
  
  prop :id, type: t.non_empty_str
  
  # prop :repo, type: QB::Docker::Repo
  # 
  # prop :tag, type: QB::Docker::Image::Tag
  
  
  # Instance Methods
  # ======================================================================
  
  
end; end; end # class QB::Docker::Image
