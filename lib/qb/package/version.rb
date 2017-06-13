module QB
  module Package
    # An attempt to unify NPM and Gem version schemes to a reasonable extend, 
    # and hopefully cover whatever else the cat may drag in.
    class Version
      # Create a Version instance from a Gem::Version
      def self.from_gem_version version
        release_segments = version.segments.take_while {|seg| !seg.is_a?(String)}
        prerelease_segments = version.segments[release_segments.length..-1]
        
        new raw: version.to_s,
            major: release_segments[0],
            minor: release_segments[1],
            patch: release_segments[2],
            prerelease: prerelease_segments,
            build: [],
            release: version.release.to_s
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
            build: parse['build'],
            release: [parse['major'], parse['minor'], parse['patch']].join(".")
      end
      
      def self.from_string string
        if string.include? '-'
          self.from_npm_version string
        else
          self.from_gem_version Gem::Version.new(string)
        end
      end
      
      # Construct a new Version
      def initialize raw:, major:, minor:, patch:, prerelease:, build:, release:
        @raw = raw
        @major = major
        @minor = minor
        @patch = patch
        @prerelease = prerelease
        @build = build
        @release = release
        
        @level = @prerelease[0] || 'release'
        
        @is_release = @prerelease.empty?
        @is_dev = @prerelease[0] == 'dev'
        @is_rc = @prerelease[0] == 'rc'
      end
      
      # dump all instance variables into a hash
      def to_h
        instance_variables.map {|var| 
          [var[1..-1], instance_variable_get(var)]
        }.to_h
      end # #to_h
      
      # Dump all instance variables in JSON serialization
      def to_json *args
        to_h.to_json *args
      end
      
      def to_s
        "#<QB::Package::Version #{ @raw }>"
      end
    end
  end # Package
end # QB