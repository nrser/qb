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

require_relative './tag'


# Refinements
# ========================================================================

require 'nrser/refinements/types'
using NRSER::Types


# Definitions
# =======================================================================

# Image name.
#  
# Input format will be one of:
#  
# 1.  name[:tag]
# 2.  repository/name[:tag]
# 3.  registry_server:port/name[:tag]
#   
module  QB
module  Docker
class   Image < QB::Data::Immutable
class   Name  < QB::Data::Immutable
  
  # Mixins
  # ========================================================================
  
  extend ::MethodDecorators
  
  include NRSER::Log::Mixin
  
  
  # Class Methods
  # ======================================================================
  
  # Load from a {String}.
  # 
  # @param [String] string
  # @return [self]
  # 
  def self.from_s string
    strings = {}
    segments = string.split '/'
    
    if segments[-1].include? ':'
      rest, _, tag = segments[-1].rpartition ':'
      strings[:tag] = tag
      segments[-1] = rest
    else
      rest = string
    end
    
    case segments.length
    when 0
      # Pass - construction will error
    when 1
      # Just a name
      strings[:name] = segments[0]
    else
      if segments[0].include? ':'
        # segments = [s_0, s_1, ... s_n]
        #   =>  repository = s_0
        #       segments = [s_1, s_2, ... s_n]
        # 
        # like
        # 
        # segments = ['docker.beiarea.com:8888', 'beiarea', 'wall']
        #   =>  registry_server = 'docker.beiarea.com'
        #       port            = '8888'
        #       segments        = ['beiarea', 'wall']
        # 
        registry_server, _, port = segments.shift.rpartition ':'
        strings[:registry_server] = registry_server
        strings[:port] = port
      end
      
      if segments.length > 1
        # segments = [s_0, s_1, ... s_m]
        #   =>  repository  = s_0
        #       segments    = [s_1, s_2, ... s_m]
        # 
        # like
        # 
        # segments = ['beiarea', 'wall']
        #   =>  repository  = 'beiarea'
        #       segments    = ['wall']
        # 
        repository = segments.shift
        strings[:repository] = repository
      end
      
      # I think Docker image names *can* have more than just a repo and name
      # segment, though it's poorly supported from what I recall... though
      # we will handle it by just re-joining whatever's left into the name.
      # 
      # segments = [s_0, s_1, ... s_p]
      #   =>  name = "s_0/s_1/.../s_p"
      # 
      # like
      # 
      # segments = ['wall']
      #   =>  name = 'wall'
      # 
      # or
      # 
      # segments = ['www_rails', 'web']
      #   =>  name = 'www_rails/web'
      # 
      strings[:name] = segments.join '/'
    end
    
    logger.debug "strings", strings
    
    # Now turn them into value using their prop types
    values = strings.transform_values_with_keys { |name, string|
      prop = metadata[name]
      
      if prop.type.respond_to? :from_s
        prop.type.from_s string
      else
        string
      end
    }
    
    logger.debug "values", values
    
    # And construct!
    new source: string, **values
  end # .from_s
  
  
  # Get an instance from a source.
  # 
  # @param [self | String | Hash] source
  # @return [self]
  # 
  def self.from source
    t.match source,
      self,     source,
      t.str,    method( :from_s ),
      t.hash_,  method( :from_data )
  end # .from
  
  
  # Queries
  # --------------------------------------------------------------------------
  
  # @see QB::Docker::CLI.image_named?
  # 
  def self.exists? name
    QB::Docker::CLI.image_named? name
  end # .exists?
  
  
  def self.all
    QB::Docker::CLI.image_names load: true, only_named: true
  end
  
  
  # @see QB::Docker::CLI.image_names
  # 
  def self.list **attrs
    return all if attrs.empty?
    
    type = t.attrs attrs
    all.select { |name| type === name }
  end # .list
  
  
  # Props
  # ======================================================================
  
  # @!attribute [r] source
  #   Source string this name was loaded from, if any.
  #   
  #   @return [String?]
  #   
  prop  :source,
        type: t.non_empty_str?
  
  
  # @!attribute [r] name
  #   For lack of a better name, the part of the name that's not anything
  #   else. It's also the only required part.
  #   
  #   @return [String]
  #     Can't be empty.
  # 
  prop  :name,
        type: t.non_empty_str
  
  
  # @!attribute [r] repository
  #   The repository name, if any.
  #   
  #   @return [String?]
  #     String is non-empty.
  prop  :repository,
        aliases: [ :repo ],
        type: t.non_empty_str?
  
  
  # @!attribute [r] registry_server
  #   Registry server, if any.
  #   
  #   @return [String?]
  #     String is non-empty.
  prop  :registry_server,
        aliases: [ :reg ],
        type: t.non_empty_str?
  
  
  # @!attribute [r] port
  #   Registry server port, if any.
  #   
  #   @return [Integer?]
  #     In range [1, 2**16 - 1]
  prop  :port,
        type: t.port?
  
  
  prop  :tag,
        type: t.maybe( QB::Docker::Image::Tag )
  
  
  prop  :string,
        type: t.non_empty_str,
        source: :to_s
  
  
  invariant ~t.attrs( registry_server: t.nil, port: ~t.nil )
  
  
  # Instance Methods
  # ======================================================================
  
  # Does the name exist in the local daemon?
  # 
  # @see QB::Docker::CLI.image_named?
  # 
  # @return [Boolean]
  # 
  def exists?
    QB::Docker::CLI.image_named? self
  end # #exist?
  
  alias_method :exist?, :exists?
  
  
  # @todo Document dirty? method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def dirty?
    !!tag.try( :dirty? )
  end # #dirty?
  
  
  def host
    return unless registry_server
    
    if port
      "#{ registry_server }:#{ port }"
    else
      registry_server
    end
  end
  
  
  def formatted
    [
      host,
      repository,
      name,
    ].compact.join( '/' ).thru { |without_tag|
      if tag
        "#{ without_tag }:#{ tag }"
      else
        without_tag
      end
    }
  end
  
  
  def to_s
    formatted
  end
  
  
  def inspect
    "#<#{ self.class.safe_name } #{ to_s }>"
  end
  
  
  def pretty_print q
    q.text inspect
  end
  
  
end; end; end; end # class QB::Docker::Image::Name
