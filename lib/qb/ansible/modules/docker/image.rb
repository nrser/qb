# encoding: UTF-8
# frozen_string_literal: true


# Requirements
# ========================================================================

# Project / Package
# ------------------------------------------------------------------------

require 'qb'
require 'qb/docker/image'


# Namespace
# ========================================================================

module QB
module Ansible
module Modules
module Docker


# Definitions
# =======================================================================

# Build a Docker image if needed. Features to deal with version-tagging.
# 
# @note Immutable.
# 
class Image < QB::Ansible::Module
  
  # @!group Argument Attributes
  # ==========================================================================
  
  # @!attribute [r] name
  #   Name that uniquely identifies the image.
  #   
  #   Used to:
  #   
  #   1.  Identify it in the local Docker daemon.
  #   2.  Pull it from a remote repository.
  #   3.  Tag it when built.
  #   
  #   @return [QB::Docker::Image::Name]
  #   
  arg :name,
      type: QB::Docker::Image::Name
  
  
  # @!attribute [r] path
  #   Path to the image source directory.
  #   
  #   @return [String | Pathname]
  #   
  arg :path,
      type: t.dir_path
      # FIXME ( from_s: ->( s ) { Pathname.new( s ).expand_path } )
  
  
  # @!attribute [r] from_image
  #   Image to build `FROM`, which will be provided as the `from_image` Docker
  #   build arg.
  #   
  #   @return [QB::Docker::Image::Name?]
  #   
  #   @todo
  #     This should be optional, and was switched to optional to hack a
  #     specific descendent into working, but changes need to be made for
  #     this role to actually handle a `nil` value.
  #   
  arg :from_image,
      type: t.maybe( QB::Docker::Image::Name )
  
  
  # @!attribute [r] fact_name
  #   Name of fact to set in Ansible with the result.
  #   
  #   Exists so that build roles can not really need to do anything else except
  #   for invoke this module, since they need to "return" values by setting
  #   global variables (yuck a duck).
  #   
  #   @return [String]
  #     Must not be empty.
  #   
  #   @todo This should be restricted to valid Ansible variable names.
  #   
  arg :fact_name,
      type: t.non_empty_str?
  
  
  # @!attribute [r] build_arg
  #   Map of additional Docker build arg names to values.
  #   
  #   @return [Hash<String, String>]
  #   
  #   @todo
  #     I think this is singular instead of `build_args` to match the Ansible
  #     `docker_image` module, but I don't think that's relevant anymore,
  #     and singular is more confusing in my opinion... should be `build_args`?
  #     
  #     Should prob also be immutable.
  #   
  arg :build_arg,
      type: t.hash_,
      aliases: [ :build_args, :buildargs ],
      reader: {
        build_args: false,
        buildargs: false,
      },
      default: ->{ {} }
  
  
  # @!attribute [r] include_from_image_build
  #   Flag argument controlling whether the {QB::Package::Version#build}
  #   segments in {#from_image}'s {QB::Docker::Image::Tag} should be added
  #   to built images' own `.tag.version.build`.
  #   
  #   "From image" build information can be very useful as part of an image
  #   tag, but it is not always necessary, and things can quickly get out of
  #   hand when the stack of versioned images gets deep.
  #   
  #   @return [Boolean]
  #   
  arg :include_from_image_build,
      type: t.bool,
      default: true
  
  
  # @!attribute [r] now
  #   The time to use as now. Defaults to get the current time, but here so
  #   that it can be provided externally so if you're doing a bunch of work
  #   you can make all the timestamps sync up. Pls don't abuse.
  #   
  #   @return [Time]
  #     UTC {Time} to use as now.
  # 
  arg :now,
      type: Time,
      default: ->{ Time.now.utc }
  
  
  # @!attribute [r] force
  #   Optional explicit control of {#force?}'s return value, which is
  #   passed as the `force:` keyword to {QB::Docker::Image.ensure_present!}.
  #   
  #   @return [Boolean]
  #     The `force:` keyword in {QB::Docker::Image.ensure_present!} will be
  #     provided this value.
  #   
  #   @return [nil]
  #     Force behavior will be determined by logic in {#force?} using
  #     information about the {QB::Package::Version::Leveled#level} being
  #     built and the state of source repo.
  #   
  #   @see #force?
  # 
  arg :force,
      type: t.bool?
  
  # @!endgroup Argument Attributes # *****************************************
  
  
  # Helpers
  # ========================================================================
  
  # 'openresty/openresty:1.11.2.4-xenial'
  #   =>  repository: 'openresty'
  #       name: 'openresty'
  #       tag: {
  #         major: 1,
  #         minor: 11,
  #         patch: 2,
  #         revision: [4],
  #         prerelease: ['xenial'],
  #       }
  #   =>  ['openresty--openresty', 1, 11, 2, 4, 'xenial']
  # 
  #   which eventually becomes the Docker tag
  #   
  #       <semver>_openresty.openresty.1.11.2.4.xenial.<build_info?>
  # 
  def build_segments_for_from_image
    return [] unless include_from_image_build
    
    [
      [
        # TODO Remove `beiarea`, needs to moved to an arg of some type.
        (from_image.repository == 'beiarea' ? nil : from_image.repository),
        from_image.name,
      ].
        compact.
        map { |name| name.gsub( '_', '-' ) }.
        join( '-' ),
      *from_image.tag.version.to_a.flatten,
    ]
  end
  
  
  def git
    lazy_var :@git do
      QB::Repo::Git.from_path path
    end
  end
  
  
  def source_base_version
    lazy_var :@source_base_version do
      QB::Package::Version.from_string (path.to_pn / 'VERSION').read
    end
  end
  
  
  def source_dev_version
    lazy_var :@source_dev_version do
      source_base_version.build_version \
        branch: git.branch,
        ref: git.head_short,
        dirty: !git.clean?
        # time: now
    end
  end
  
  
  def source_version
    lazy_var :@source_version do
      if source_base_version.dev?
        source_dev_version
      else
        source_non_dev_version
      end
    end
  end
  
  
  def source_non_dev_version
    tag = "v#{ source_base_version.semver }"
    
    # We check...
    # 
    # 1.  Repo is clean
    unless git.clean?
      raise "Can't build #{ source_base_version.level } version from " \
            "dirty repo"
    end
    
    # 2.  Tag exists
    unless git.tags.include? tag
      raise "Tag #{ tag } not found"
    end
    
    # 3.  Tag points to current commit
    tag_commit = Cmds.
      new( "git rev-list -n 1 %s", chdir: path ).
      out!( tag ).
      chomp
    
    unless tag_commit == git.head
      raise "Repo is not at tag #{ tag } commit #{ tag_commit }"
    end
    
    # Ok, we just use the version in the file!
    source_base_version
  end
  
  
  def image_version
    lazy_var :@image_version do
      source_version.merge \
        build: [
          *build_segments_for_from_image,
          *source_version.build
        ]
    end
  end
  
  
  def image_name
    lazy_var :@image_name do
      name.merge \
        source: nil, # NEED this!
        tag: QB::Docker::Image::Tag.from_s(
          image_version.docker_tag
        )
    end
  end
  
  
  def repo_clean?
    lazy_var :@repo_clean do
      git.clean?
    end
  end
  
  
  def repo_dirty?
    !repo_clean?
  end
  
  
  def force?
    if force.nil?
      source_base_version.dev? && repo_dirty?
    else
      force
    end
  end
  
  
  # Execution
  # ==========================================================================
  
  # Entry point for the module. invoked by {#run!}.
  # 
  # @return [nil | {Symbol => #to_json}]
  #   when returning:
  #   
  #   -   `nil`: module will successfully exit with no additional changes.
  #       
  #   -   `{Symbol => #to_json}`: Hash will be merged over @facts that
  #       are returned by the module to be set in the Ansible runtime and
  #       the module will exit successfully.
  #       
  def main
    logger.trace \
      "Starting `#main`...",
      path: path,
      from_image: from_image.to_s,
      build_arg: build_arg,
      fact_name: fact_name
      
    
    QB::Docker::Image.ensure_present! \
      name: image_name,
      pull: !image_version.dev?,
      build: {
        path: path,
        build_arg: {
          from_image: from_image.string,
          image_version: image_version.semver,
          **build_arg.to_options,
        },
      },
      # Don't push dev images
      push: !image_version.dev?,
      force: force?
    
    response[:image] = {
      name: image_name,
      version: image_version,
    }
    
    if fact_name
      response.facts[fact_name] = response[:image]
    end
    
    return nil
  end # #main
  
end # class Image


# /Namespace
# ========================================================================

end # module Docker
end # module Modules
end # module Ansible
end # module QB
