# frozen_string_literal: true


# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------
require 'semver'

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================

using NRSER
using NRSER::Types


# Definitions
# =======================================================================

# Module of factory methods to create {QB::Package::Version} instances from
# other objects (strings, {Gem::Version}, etc.)
# 
module QB::Package::Version::From
  
  # Get class to instantiate for prop values - either {QB::Package::Version}
  # or a specialized subclass like {QB::Package::Version::Leveled}.
  # 
  # @param [Hash<Symbol, Object>] **values
  #   Prop values.
  # 
  # @return [Class<QB::Package::Version>]
  # 
  def self.class_for **values
    if QB::Package::Version::Leveled.level_for **values
      QB::Package::Version::Leveled
    else
      QB::Package::Version
    end
  end # .class_for
  
  
  # Instantiate an instance from prop values, using {.class_for} to choose
  # the possible specialized class.
  # 
  # @param [Hash<Symbol, Object>] **values
  #   Prop values.
  # 
  # @return [QB::Package::Version]
  # 
  def self.prop_values **values
    class_for( **values ).new **values
  end # .values
  
  
  # Create an instance from a Gem-style version.
  # 
  # @param [String | Gem::Version] version
  # 
  # @return [QB::Package::Version]
  # 
  def self.gemver source
    gem_version = case source
    when ::Gem::Version
      source
    else
      ::Gem::Version.new source.to_s
    end
    
    # release segments are everything before a string
    release_segments = gem_version.segments.take_while { |seg|
      !seg.is_a?(String)
    }
    
    # We don't support > 3 release segments to make life somewhat
    # reasonable. Yeah, I think I've seen projects do it. We'll cross that
    # bridge if and when we get to it.
    if release_segments.length > 3
      raise ArgumentError,
            "We don't handle releases with more than 3 segments " +
            "(found #{ release_segments.inspect } in #{ gem_version })"
    end
    
    prerelease_segments = gem_version.segments[release_segments.length..-1]
    
    prop_values \
      raw: source.to_s,
      major: release_segments[0],
      minor: release_segments[1] || 0,
      patch: release_segments[2] || 0,
      prerelease: prerelease_segments,
      build: []
  end
  
  singleton_class.send :alias_method, :gem_version, :gemver
  
  
  def self.split_identifiers string
    string.split QB::Package::Version::IDENTIFIER_SEPARATOR
  end
  
  
  # Parse and/or validate version *identifiers*.
  # 
  # See {QB::Package::Version} for details on *identifiers*.
  # 
  # @param [String | Integer] value
  #   A value that is either already an *identifier* or a string that can
  #   be parsed into one.
  # 
  # @return [String | Integer]
  #   A valid *identifier*.
  # 
  def self.identifier_for value
    case value
    when QB::Package::Version::NUMBER_IDENTIFIER_RE
      value.to_i
    when  QB::Package::Version::MIXED_SEGMENT
      value
    else
      raise ArgumentError.new binding.erb <<~END
        Can't parse identifier <%= value.inspect %>
        
        Expected one of:
        
        1.  <%= QB::Package::Version::NUMBER_IDENTIFIER_RE %>
        2.  <%= QB::Package::Version::MIXED_SEGMENT %>
        
      END
    end
  end # .identifier_for
  
  
  def self.segment_for string
    split_identifiers( string ).map { |s| identifier_for s }
  end
  

  def self.semver version
    parse = SemVer.parse version
    
    prop_values \
      raw: version,
      major: parse.major,
      minor: parse.minor,
      patch: parse.patch,
      prerelease: segment_for( parse.prerelease ),
      build: segment_for( parse.metadata )
  end
  
  singleton_class.send :alias_method, :npm_version, :semver


  # Parse Docker image tag version and create an instance.
  # 
  # @param [String] version
  #   String version to parse.
  # 
  # @return [QB::Package::Version]
  # 
  def self.docker_tag version
    string( version.gsub( '_', '+' ) ).merge raw: version
  end # .docker_tag


  # Parse string version into an instance. Accept Semver, Ruby Gem and
  # Docker image tag formats.
  # 
  # @param [String]
  #   String version to parse.
  # 
  # @return [QB::Package::Version]
  # 
  def self.string string
    if string.empty?
      raise ArgumentError.new binding.erb <<~END
        Can not parse version from empty string.
        
        Requires at least a major version.
        
      END
    end
    
    if string.include? '_'
      docker_tag string
    elsif string.include?( '-' ) || string.include?( '+' )
      semver string
    else
      gemver string
    end
  end

  singleton_class.send :alias_method, :s, :string
  
  
  def self.object object
    case object
    when String
      string object
    when Hash
      prop_values **object
    when ::Gem::Version
      gemver object
    else
      raise TypeError.new binding.erb <<-END
        `object` must be String, Hash or Gem::Version
        
        Found:
        
            <%= object.pretty_inspect %>
        
      END
    end
  end
  
end # module QB::Package::Version::From
