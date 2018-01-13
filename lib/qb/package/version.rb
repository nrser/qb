# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------
require 'time'

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------
require 'qb/util/docker_mixin'
require 'qb/util/resource'


# Refinements
# =======================================================================

require 'nrser/refinements'
using NRSER

require 'nrser/refinements/types'
using NRSER::Types


# Declarations
# =======================================================================

module QB; end
class QB::Package < QB::Util::Resource; end


# Definitions
# =======================================================================

# An attempt to unify NPM and Gem version schemes to a reasonable extend,
# and hopefully cover whatever else the cat may drag in.
# 
# Intended to be immutable for practical purposes.
# 
class QB::Package::Version < QB::Util::Resource
  
  # Mixins
  # =====================================================================
  
  include Comparable
  include QB::Util::DockerMixin
  
  
  # Constants
  # =====================================================================
  
  NUMBER_SEGMENT = t.non_neg_int
  NAME_SEGMENT = t.str
  MIXED_SEGMENT = t.union NUMBER_SEGMENT, NAME_SEGMENT
  
  
  # Reasonably simple regular expression to extract things that might be
  # versions from strings.
  # 
  # Intended for use on reasonably short strings like `git tag` output or
  # what-not... probably not well suited for sifting through mountains of
  # text.
  # 
  # Structure:
  # 
  # 1.  The major version number, matched by a digit `1-9` followed by any
  #     number of digits.
  # 2.  A separator to the next segment, which is:
  #     1.  `.` separating to the minor version number
  #     2.  `-` separating to the prerelease
  #     3.  `+` separating to the build
  # 3.  One or more of `a-z`, `A-Z`, `0-9`, `.`, `-`, `_`, `+`
  # 4.  Ends with one of those that is *not* `.`, `_` or `+`, so `a-z`, `A-Z`,
  #     `0-9`.
  # 
  # This will match *many* strings that are not versions, but it should not
  # miss any that are. It cold obviously be refined and improve to reduce
  # false positives at the cost of additional complexity, but I wanted to
  # start simple and complicate it as needed.
  # 
  # @return [Regexp]
  # 
  POSSIBLE_VERSION_RE = \
    /(?:0|[1-9]\d*)[\.\-\+][a-zA-Z0-9\.\-\_\+]*[a-zA-Z0-9\-]+/
  
  
  # Props
  # =====================================================================

  prop :raw,            type: t.maybe(t.str),         default: nil
  prop :major,          type: NUMBER_SEGMENT
  prop :minor,          type: NUMBER_SEGMENT,         default: 0
  prop :patch,          type: NUMBER_SEGMENT,         default: 0
  prop :prerelease,     type: t.array(MIXED_SEGMENT), default: []
  prop :build,          type: t.array(MIXED_SEGMENT), default: []

  prop :release,        type: t.str,            source: :@release
  prop :is_release,     type: t.bool,           source: :release?
  prop :is_prerelease,  type: t.bool,           source: :prerelease?
  prop :is_build,       type: t.bool,           source: :build?
  prop :semver,         type: t.str,            source: :semver
  prop :docker_tag,     type: t.str,            source: :docker_tag
  prop :build_commit,   type: t.maybe(t.str),   source: :build_commit
  prop :is_build_dirty, type: t.maybe(t.bool),  source: :build_dirty?


  # Attributes
  # =====================================================================

  attr_reader :release
  
  
  # Class Methods
  # =====================================================================
  
  # Utilities
  # ---------------------------------------------------------------------
  
  def self.from object
    QB::Package::Version::From.object object
  end
  
  
  # @depreciated Use {.from} instead.
  # 
  def self.from_string string
    QB::Package::Version::From.string string
  end
  
  singleton_class.send :alias_method, :from_s, :from_string
  
  
  # Time formatted to be stuck in a version segment per [Semver][] spec.
  # We also strip out '-' to avoid possible parsing weirdness.
  # 
  # [Semver]: https://semver.org/
  # 
  # @return [String]
  # 
  def self.to_time_segment time
    time.utc.iso8601.gsub /[^0-9A-Za-z]/, ''
  end
  
  
  # Extract version number from a string.
  # 
  # @param [String] string
  #   String containing versions.
  # 
  # @return [Array<QB::Package::Version]
  #   Any versions extracted from the string.
  # 
  def self.extract string
    string.scan( POSSIBLE_VERSION_RE ).map { |possible_version_string|
      begin
        from possible_version_string
      rescue
        nil
      end
    }.compact
  end # .extract
  
  
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
  
  
  # Derived Properties
  # ---------------------------------------------------------------------
  
  def release
    [major, minor, patch].join '.'
  end
  
  
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
    self.class.from release
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
  
  
  def <=> other
    to_a <=> other.to_a
  end
  
  
  # Return array of the version elements in order from greatest to least
  # precedence.
  # 
  # This is considered the representative structure for the object's data,
  # from which all other values are dependently derived, and is used in
  # {#==}, {#hash} and {#eql?}.
  # 
  # @example
  #   
  #   version = QB::Package::Version.from "0.1.2-rc.10+master.0ab1c3d"
  #   
  #   version.to_a
  #   # => [0, 1, 2, ['rc', 10], ['master', '0ab1c3d']]
  #   
  #   QB::Package::Version.from( '1' ).to_a
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
  
end # class QB::Package::Version


# Post-Processing
# =======================================================================

require 'qb/package/version/leveled'
require 'qb/package/version/from'
