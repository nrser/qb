require 'time'

require 'nrser/refinements/types'

using NRSER::Types

require 'qb/util/docker_mixin'

module QB
  module Package
    # An attempt to unify NPM and Gem version schemes to a reasonable extend, 
    # and hopefully cover whatever else the cat may drag in.
    # 
    # Intended to be immutable for practical purposes.
    # 
    class Version < NRSER::Meta::Props::Base
      
      # Mixins
      # =====================================================================
      
      include QB::Util::DockerMixin
      
      
      # Constants
      # =====================================================================
      
      NUMBER_SEGMENT = t.non_neg_int
      NAME_SEGMENT = t.str
      MIXED_SEGMENT = t.union NUMBER_SEGMENT, NAME_SEGMENT
      
      
      # Props
      # =====================================================================

      prop :raw,            type: t.maybe(t.str),         default: nil
      prop :major,          type: NUMBER_SEGMENT
      prop :minor,          type: NUMBER_SEGMENT,         default: 0
      prop :patch,          type: NUMBER_SEGMENT,         default: 0
      prop :prerelease,     type: t.array(MIXED_SEGMENT), default: []
      prop :build,          type: t.array(MIXED_SEGMENT), default: []

      prop :release,        type: t.str,            source: :@release
      prop :level,          type: t.str,            source: :@level
      prop :is_release,     type: t.bool,           source: :release?
      prop :is_prerelease,  type: t.bool,           source: :prerelease?
      prop :is_build,       type: t.bool,           source: :build?
      prop :is_dev,         type: t.bool,           source: :dev?
      prop :is_rc,          type: t.bool,           source: :rc?
      prop :has_level,      type: t.bool,           source: :level?
      prop :semver,         type: t.str,            source: :semver
      prop :docker_tag,     type: t.str,            source: :docker_tag
      prop :build_commit,   type: t.maybe(t.str),   source: :build_commit
      prop :is_build_dirty, type: t.maybe(t.bool),  source: :build_dirty?


      # Attributes
      # =====================================================================

      attr_reader :release,
                  :level
      
      
      # Class Methods
      # =====================================================================
      
      # Utilities
      # ---------------------------------------------------------------------
      
      # @return [String]
      #   Time formatted to be stuck in a version segment per Semver spec.
      #   We also strip out '-' to avoid possible parsing weirdness.
      def self.to_time_segment time
        time.utc.iso8601.gsub /[^0-9A-Za-z]/, ''
      end
      
      
      # Instance Builders
      # ---------------------------------------------------------------------
      
      # Create a Version instance from a Gem::Version
      def self.from_gem_version version
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
        
        new raw: version.to_s,
            major: release_segments[0] || 0,
            minor: release_segments[1] || 0,
            patch: release_segments[2] || 0,
            prerelease: prerelease_segments,
            build: []
      end
      
      def self.from_npm_version version
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
        
        new raw: version,
            major: parse['major'],
            minor: parse['minor'],
            patch: parse['patch'],
            prerelease: parse['prerelease'],
            build: parse['build']
      end
      
      
      # Parse Docker image tag version into a string. Reverse of 
      # {QB::Package::Version#docker_tag}.
      # 
      # @param [String] version
      #   String version to parse.
      # 
      # @return [QB::Package::Version]
      # 
      def self.from_docker_tag version
        from_string(version.gsub('_', '+')).merge raw: version
      end # .from_docker_tag
      
      
      
      # Parse string version into an instance. Accept Semver, Ruby Gem and 
      # Docker image tag formats.
      # 
      # @param [String]
      #   String version to parse.
      # 
      # @return [QB::Package::Version]
      # 
      def self.from_string string
        if string.include? '_'
          self.from_docker_tag string
        elsif string.include? '-'
          self.from_npm_version string
        else
          self.from_gem_version Gem::Version.new(string)
        end
      end
      
      
      # Constructor
      # =====================================================================
      
      # Construct a new Version
      def initialize **values
        super **values
        
        @release = [major, minor, patch].join '.'
        
        @level = t.match prerelease[0], {
          t.is(nil) => ->(_) { nil },
          
          NAME_SEGMENT => ->(str) { str },
          
          NUMBER_SEGMENT => ->(int) { nil },
        }
      end
      
      
      # Instance Methods
      # =====================================================================
      
      # Tests
      # ---------------------------------------------------------------------
      
      # @return [Boolean]
      #   True if this version is a release (no prerelease or build values).
      # 
      def release?
        prerelease.empty? && build.empty?
      end
      
      
      # @return [Boolean]
      #   True if any prerelease segments are present (stuff after '-' in 
      #   SemVer / "NPM" format, or the first string segment and anything
      #   following it in "Gem" format). Tests if {@prerelease} is not
      #   empty.
      # 
      def prerelease?
        !prerelease.empty?
      end
      
      
      # @return [Boolean]
      #   True if any build segments are present (stuff after '+' character
      #   in SemVer / "NPM" format). Tests if {@build} is empty.
      #   
      #   As of writing, we don't have a way to convey build segments in 
      #  "Gem" version format, so this will always be false when loading a 
      #   Gem version.
      # 
      def build?
        !build.empty?
      end
      
      
      
      # @todo Document build_dirty? method.
      # 
      # @param [type] arg_name
      #   @todo Add name param description.
      # 
      # @return [return_type]
      #   @todo Document return value.
      # 
      def build_dirty?
        if build?
          build.include? 'dirty'
        end
      end # #build_dirty?
      
      
      
      # @return [Boolean]
      #   True if self is a prerelease version that starts with a string that
      #   we consider the 'level'.
      #   
      def level?
        !level.nil?
      end
      
      
      # @return [Boolean]
      #   True if this version is a dev prerelease (first prerelease element 
      #   is 'dev').
      # 
      def dev?
        level == 'dev'
      end
      
      
      # @return [Boolean]
      #   True if this version is a release candidate (first prerelease element
      #   is 'rc').
      # 
      def rc?
        level == 'rc'
      end
      
      
      # Derived Properties
      # ---------------------------------------------------------------------
      
      # @return [String]
      #   The Semver version string
      #   (`Major.minor.patch-prerelease+build` format).
      # 
      def semver
        result = release
        
        unless prerelease.empty?
          result += "-#{ prerelease.join '.' }"
        end
        
        unless build.empty?
          result += "+#{ build.join '.' }"
        end
        
        result
      end # #semver
      
      alias_method :normalized, :semver
      
      
      # @todo Document commit method.
      # 
      # @param [type] arg_name
      #   @todo Add name param description.
      # 
      # @return [return_type]
      #   @todo Document return value.
      # 
      def build_commit
        if build?
          build.find { |seg| seg =~ /[0-9a-f]{7}/ }
        end
      end # #commit
      
      
      # Docker image tag for the version.
      # 
      # See {QB::Util::DockerMixin::ClassMethods#to_docker_tag}.
      # 
      # @return [String]
      #   
      def docker_tag
        self.class.to_docker_tag semver
      end # #docker_tag
      
      
      # Related Versions
      # ---------------------------------------------------------------------
      # 
      # Functions that construct new version instances based on the current 
      # one as well as additional information provided.
      # 
      
      # @return [QB::Package::Version]
      #   A new {QB::Package::Version} created from {#release}. Even if `self`
      #   *is* a release version already, still returns a new instance.
      # 
      def release_version
        self.class.from_string release
      end # #release_version
      
      
      # Return a new {QB::Package::Version} with build information added.
      # 
      # @return [QB::Package::Version]
      # 
      def build_version branch: nil, ref: nil, time: nil, dirty: nil
        time = self.class.to_time_segment(time) unless time.nil?
        
        segments = [
          branch,
          ref,
          ('dirty' if dirty),
          time,
        ].reject &:nil?
        
        if segments.empty?
          raise ArgumentError,
                "Need to provide at least one of branch, ref, time."
        end
        
        merge raw: nil, build: segments
      end
      
      
      # @return [QB::Package::Version]
      #   A new {QB::Package::Version} created from {#release} and
      #   {#prerelease} data, but without any build information.
      # 
      def prerelease_version
        merge raw: nil, build: []
      end # #prerelease_version
      
      
      
      # Language Interface
      # =====================================================================
      
      # Test for equality.
      # 
      # Compares classes then {QB::Package::Version#to_a} results.
      # 
      # @param [Object] other
      #   Object to compare to self.
      # 
      # @return [Boolean]
      #   True if self and other are considered equal.
      # 
      def == other
        other.class == self.class &&
        other.to_a == self.to_a 
      end # #==
      
      
      # Return array of the version elements in order from greatest to least
      # precedence.
      # 
      # This is considered the representative structure for the object's data,
      # from which all other values are dependently derived, and is used in 
      # {#==}, {#hash} and {#eql?}.
      # 
      # @example
      #   
      #   version = QB::Package::Version.from_string(
      #     "0.1.2-rc.10+master.0ab1c3d"
      #   )
      #   
      #   version.to_a
      #   # => [0, 1, 2, ['rc', 10], ['master', '0ab1c3d']]
      #   
      #   QB::Package::Version.from_string('1').to_a
      #   # => [1, nil, nil, [], []]
      # 
      # @return [Array]
      # 
      def to_a
        [
          major,
          minor,
          patch,
          prerelease,
          build,
        ]
      end # #to_a
      
      
      def hash
        to_a.hash
      end
      
      
      def eql? other
        self == other && self.hash == other.hash
      end
      
      
      def to_s
        "#<QB::Package::Version #{ @raw }>"
      end
      
    end # class Version
  end # Package
end # QB