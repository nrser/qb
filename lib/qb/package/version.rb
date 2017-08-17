require 'time'

require 'nrser/types'

require 'qb/util/docker_mixin'

T = NRSER::Types

module QB
  module Package
    # An attempt to unify NPM and Gem version schemes to a reasonable extend, 
    # and hopefully cover whatever else the cat may drag in.
    # 
    # Intended to be immutable for practical purposes.
    # 
    class Version
      include QB::Util::DockerMixin
      
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
        from_string version.gsub('_', '+')
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
        if string.include? '-'
          self.from_npm_version string
        elsif string.include? '_'
          self.from_docker_tag string
        else
          self.from_gem_version Gem::Version.new(string)
        end
      end
      
      
      # Instantiate from a hash. Slices out
      # 
      # -   `raw`
      # -   `major`
      # -   `minor`
      # -   `patch`
      # -   `prerelease`
      # -   `build`
      # 
      # And passes their values to the constructor. Keys may be strings or 
      # symbols. All other key/values are ignored, allowing you to pass in 
      # the JSON encoding of a version instance.
      # 
      # @param [Hash] hash
      #   Values to be passed to constructor.
      # 
      # @return [QB::Package::Version]
      # 
      def self.from_h hash
        self.new(
          NRSER.slice_keys(
            NRSER.symbolize_keys(hash),
            :raw,
            :major,
            :minor,
            :patch,
            :prerelease,
            :build,
          )
        )
      end # #from_h
      
      
      
      # Attributes
      # =====================================================================
      
      attr_reader :raw,
                  :major,
                  :minor,
                  :patch,
                  :prerelease,
                  :build,
                  :release,
                  :level
      
      
      # Constructor
      # =====================================================================
      
      # Construct a new Version
      def initialize(
        raw: nil,
        major:,
        minor: 0,
        patch: 0,
        prerelease: [],
        build: []
      )
        @raw = T.maybe(T.str).check raw
        @major = T.non_neg_int.check major
        @minor = T.non_neg_int.check minor
        @patch = T.non_neg_int.check patch
        @prerelease = T.array(T.union(T.non_neg_int, T.str)).check prerelease
        @build = T.array(T.union(T.non_neg_int, T.str)).check build
        @release = [major, minor, patch].join '.'
        
        @level = T.match @prerelease[0], {
          T.is(nil) => ->(_) { nil },
          
          T.str => ->(str) { str },
          
          T.non_neg_int => ->(int) { nil },
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
        @prerelease.empty? && @build.empty?
      end
      
      
      # @return [Boolean]
      #   True if any prerelease segments are present (stuff after '-' in 
      #   SemVer / "NPM" format, or the first string segment and anything
      #   following it in "Gem" format). Tests if {@prerelease} is not
      #   empty.
      # 
      def prerelease?
        !@prerelease.empty?
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
        !@build.empty?
      end
      
      
      # @return [Boolean]
      #   True if self is a prerelease version that starts with a string that
      #   we consider the 'level'.
      #   
      def level?
        !@level.nil?
      end
      
      
      # @return [Boolean]
      #   True if this version is a dev prerelease (first prerelease element 
      #   is 'dev').
      # 
      def dev?
        @level == 'dev'
      end
      
      
      # @return [Boolean]
      #   True if this version is a release candidate (first prerelease element
      #   is 'rc').
      # 
      def rc?
        @level == 'rc'
      end
      
      
      # Transformations
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
      
      
      # @return [QB::Package::Version]
      #   A new {QB::Package::Version} created from {#release}. Even if `self`
      #   *is* a release version already, still returns a new instance.
      # 
      def release_version
        self.class.from_string release
      end # #release_version
      
      
      def merge overrides = {}
        self.class.from_h self.to_h.merge(overrides)
      end
      
      
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
      
      # Docker image tag for the version.
      # 
      # See {QB::Util::DockerMixin::ClassMethods#to_docker_tag}.
      # 
      # @return [String]
      #   
      def docker_tag
        self.class.to_docker_tag semver
      end # #docker_tag
      
      
      
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
      
      
      # dump all instance variables into a hash
      def to_h
        instance_variables.map {|var| 
          [var[1..-1], instance_variable_get(var)]
        }.to_h
      end # #to_h
      
      
      # Dump all instance variables in JSON serialization
      def to_json *args
        to_h.merge(
          is_release: release?,
          is_prerelease: prerelease?,
          is_build: build?,
          is_dev: dev?,
          is_rc: rc?,
          has_level: level?,
          semver: semver,
          docker_tag: docker_tag,
        ).to_json *args
      end
      
      
      def to_s
        "#<QB::Package::Version #{ @raw }>"
      end
      
    end # class Version
  end # Package
end # QB