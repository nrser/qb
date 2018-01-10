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
  
  LEVELS = Set['dev', 'rc', 'release']
  
  module Types
    LEVEL = t.in LEVELS, name: 'LevelType'
    
    def self.level; LEVEL; end
  end
  
  # Props
  # ============================================================================
  
  prop :level,  type: Types.level,   source: :level
  
  
  # Instance Methods
  # ============================================================================
  
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
  def transition_to_dev
    props = { prerelease: ['dev'] }
    
    case self.level
    when 'release'
      merge patch: patch.succ, **props
    when 'rc'
      merge **props
    when 'dev'
      self
    end
  end # #bump_dev


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
    case self.level
    when 'release'
      merge patch: patch.succ, prerelease: ['rc', 0]
    when 'rc'
      merge prerelease: ['rc', prerelease[1].succ]
    when 'dev'
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
    end
  end # #bump_rc


  # @todo Document transition_to_release method.
  # 
  # @return [QB::Package::Version]
  # 
  def transition_to_release
    case self.level
    when 'release'
      # bump forward to next release, M.m.p -> M.m.(p+1)
      merge patch: patch.succ
    when 'rc', 'dev'
      # bump forward to release version for rc or dev
      release_version
    end
  end # #transition_to_release


  # @todo Document bump method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def transition level:, **options
    Types.level.check level.to_s
    
    method_name = "transition_to_#{ level }"
    if options.empty?
      public_send method_name
    else
      public_send method_name, **options
    end
  end # #bump
  
  
end
