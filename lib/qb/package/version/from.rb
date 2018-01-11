# frozen_string_literal: true

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
  def self.gemver version
    version = Gem::Version.new( version ) if version.is_a?( String )
    
    # release segments are everything before a string
    release_segments = version.segments.take_while { |seg|
      !seg.is_a?(String)
    }
    
    # We don't support > 3 release segments to make life somewhat
    # reasonable. Yeah, I think I've seen projects do it. We'll cross that
    # bridge if and when we get to it.
    if release_segments.length > 3
      raise ArgumentError,
            "We don't handle releases with more than 3 segments " +
            "(found #{ release_segments.inspect } in #{ version })"
    end
    
    prerelease_segments = version.segments[release_segments.length..-1]
    
    prop_values \
      raw: version.to_s,
      major: release_segments[0] || 0,
      minor: release_segments[1] || 0,
      patch: release_segments[2] || 0,
      prerelease: prerelease_segments,
      build: []
  end
  
  singleton_class.send :alias_method, :gem_version, :gemver


  def self.semver version
    stmt = NRSER.squish <<-END
      var Semver = require('semver');
      
      console.log(
        JSON.stringify(
          Semver(#{ JSON.dump version })
        )
      );
    END
    
    parse = JSON.load Cmds.new(
      "node --eval %s", args: [stmt], chdir: QB::ROOT
    ).out!
    
    prop_values \
      raw: version,
      major: parse['major'],
      minor: parse['minor'],
      patch: parse['patch'],
      prerelease: parse['prerelease'],
      build: parse['build']
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
    if string.include? '_'
      docker_tag string
    elsif string.include?( '-' ) || string.include?( '+' )
      semver string
    else
      gem_version string
    end
  end

  singleton_class.send :alias_method, :s, :string
  
  
  def self.object object
    case object
    when String
      string object
    when Hash
      prop_values **object
    when Gem::Version
      gem_version object
    else
      raise TypeError.new binding.erb <<-END
        `object` must be String, Hash or Gem::Version
        
        Found:
        
            <%= object.pretty_inspect %>
        
      END
    end
  end
  
end # module QB::Package::Version::From
