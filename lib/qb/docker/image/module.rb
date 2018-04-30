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


# Refinements
# =======================================================================


# Declarations
# =======================================================================


# Definitions
# =======================================================================


# @todo document QB::Docker::Image::Module class.
class QB::Docker::Image::Module < QB::Ansible::Module
  
  # Arguments
    # ==========================================================================
    
    arg :path,
        type: t.dir_path # FIXME ( from_s: ->( s ) { Pathname.new( s ).expand_path } )
    
    arg :from_image,
        type: QB::Docker::Image::Name
    
    arg :fact_name,
        type: t.non_empty_str?
    
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
    
    
    # Helpers
    # ============================================================================
    
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
      [
        [
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
        QB::Docker::Image::Name.new \
          repository:   self.class.repo,
          name:         self.class.repo_name,
          tag:          QB::Docker::Image::Tag.from_s(
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
      source_base_version.dev? && repo_dirty?
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
      logger.info \
        "Starting `_image`...",
        path: path,
        from_image: from_image.to_s,
        fact_name: fact_name
        
      
      QB::Docker::Image.ensure_present! \
        name: image_name,
        pull: !image_version.dev?,
        build: {
          path: path,
          build_arg: {
            from_image: from_image.string,
            image_version: image_version.semver,
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
  
  
end # class QB::Docker::Image::Module
