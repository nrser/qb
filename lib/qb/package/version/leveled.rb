# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------
require 'qb/package/version'


# Refinements
# =======================================================================

using NRSER
using NRSER::Types


# Definitions
# =======================================================================

# An attempt to unify NPM and Gem version schemes to a reasonable extend,
# and hopefully cover whatever else the cat may drag in.
# 
# Intended to be immutable for practical purposes.
# 
class QB::Package::Version::Leveled < QB::Package::Version
  DEV = 'dev'
  RC = 'rc'
  RELEASE = 'release'
  
  LEVELS = Set[ DEV, RC, RELEASE ].freeze
  
  module Types
    LEVEL = t.in LEVELS, name: 'LevelType'
    
    def self.level
      LEVEL
    end
  end
  
  
  # Props
  # ==========================================================================
  
  prop :level,          type: Types.level,      source: :level
  prop :is_dev,         type: t.bool,           source: :dev?
  prop :is_rc,          type: t.bool,           source: :rc?
  
  
  # Class Methods
  # ==========================================================================
  
  # Get the level for version prop values. Returns `nil` if they are not
  # "leveled".
  # 
  # @param [Array<String | Integer>] prerelease:
  #   The prerelease segments of the version.
  # 
  # @param [Array<String | Integer>] build:
  #   The build segments of the version.
  # 
  # @param [Hash<Symbol, Object>] **etc
  #   Really, anything, but meant to allow you to just pass all
  #   {QB::Package::Version} prop values to the method.
  # 
  # @return [nil]
  #   If the prop values don't have a level.
  # 
  # @return ['dev' | 'rc' | 'release']
  #   If the values do have a level.
  # 
  def self.level_for prerelease: [], build: [], **etc
    return RELEASE if prerelease.empty? && build.empty?
    
    return DEV if prerelease[0] == DEV
    
    if  prerelease[0] == RC &&
        prerelease.length == 2 &&
        t.non_neg_int.test( prerelease[1] )
      return RC
    end
    
    nil
  end # .level_for
  
  
  # Just like {.level_for} but raises if the props don't represent a valid
  # level.
  # 
  # @param (see .level_for)
  # @return (see .level_for)
  # 
  # @raise [ArgumentError]
  #   If the prop values don't represent a version level.
  # 
  def self.level_for! **values
    level_for( **values ).tap { |response|
      if response.nil?
        raise ArgumentError.new binding.erb <<-END
          Prop values not valid for a leveled version:
          
              <%= values.pretty_inspect %>
          
        END
      end
    }
  end
  
  
  # Constructor
  # ==========================================================================
  
  # Construct a new Version
  def initialize **values
    # Just to do the type check...
    self.class.level_for! **values
    super **values
  end
  
  
  # Instance Methods
  # ============================================================================
  
  def level
    self.class.level_for \
      prerelease: prerelease,
      build: build
  end
  
  
  # @return [Boolean]
  #   True if this version is a dev prerelease (first prerelease element
  #   is 'dev').
  # 
  def dev?
    level == DEV
  end
  
  
  # @return [Boolean]
  #   True if this version is a release candidate (first prerelease element
  #   is 'rc').
  # 
  def rc?
    level == RC
  end
  
  
  # Transitions
  # ---------------------------------------------------------------------
  # 
  # Methods for transitioning from one level to another that abide by rules
  # for cycling between them.
  # 

  # @todo Document bump_dev method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def transition_to_dev inc: :patch
    props = { prerelease: ['dev'] }
    
    t.match level,
      'release', ->(_) {
        succ = public_send( inc ).succ
        
        merge inc => succ, **props
      },
      
      'rc', ->(_) {
        merge **props
      },
      
      'dev',  ->(_) {
        raise QB::VersionError,
          "Version #{ self } is already at `dev` level"
      }
  end # #transition_to_dev


  # Transition to next release-candidate version.
  # 
  # This is a little tricky because we need to know what the *last* rc
  # version was, which is not in the version in most cases.
  # 
  # @param [nil | String | Array] existing_versions:
  #   Required when transitioning *from* `dev` level; ignored from `rc` and
  #   `release` levels.
  #   
  #   > When transitioning from `dev` to `rc` we need to know what `rc.X`
  #   versions have already been used in order to figure out the correct
  #   next one.
  #   
  #   Value details:
  #   
  #   -   `nil` - Default value; fine when {#level} is `release` or `rc`. An
  #       {ArgumentError} will be raised if {#level} is `dev`.
  #   
  #   -   `String` -
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def transition_to_rc existing_versions: nil
    t.match level,
      'release', ->(_) {
        raise QB::VersionError,
          "Can not transition from `release` to `rc` levels (for #{ self })"
      },
      
      'rc', ->(_) {
        merge prerelease: ['rc', prerelease[1].succ]
      },
      
      'dev', ->(_) {
        if existing_versions.nil?
          raise ArgumentError.squished <<-END
            Can't bump to next rc version without knowing what rc versions have
            already been used.
          END
        elsif existing_versions.is_a? String
          existing_versions = self.class.extract existing_versions
        end
        
        last_existing_rc = existing_versions.
          select { |version|
            version.rc? && version.release == release
          }.
          sort.
          last
        
        rc_number = if last_existing_rc.nil?
          0
        else
          last_existing_rc.prerelease[1].succ
        end
        
        merge prerelease: ['rc', rc_number]
      }
  end # #transition_to_rc


  # @todo Document transition_to_release method.
  # 
  # @return [QB::Package::Version]
  # 
  def transition_to_release
    t.match level,
      'release', ->(_) {
        raise QB::VersionError,
          "Version #{ self } is already at `release` level"
      },
      
      'dev', ->(_) {
        raise QB::VersionError,
          "Can not transition from `dev` to `release` levels (for #{ self })"
      },
      
      'rc', ->(_) {
        release_version
      }
  end # #transition_to_release


  # @todo Document bump method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def transition_to level, **options
    Types.level.check level.to_s
    
    method_name = "transition_to_#{ level }"
    if options.empty?
      public_send method_name
    else
      public_send method_name, **options
    end
  end # #transition
  
  
end
