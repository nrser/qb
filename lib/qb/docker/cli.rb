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


# @todo document QB::Docker::CLI class.
module QB
module Docker
module CLI
  
  # Mixins
  # ========================================================================
  
  include NRSER::Log::Mixin
  
  extend ::MethodDecorators
  
  
  # Classes
  # ==========================================================================
  
  class Error < QB::Error
    
    # Make an instance from a {Cmds::Result}.
    # 
    # @param [Cmds::Result] result
    #   Result of command that error'd.
    # 
    # @return [self]
    # 
    def self.from_result result
      new \
        ( "Command `#{ result.cmd.truncate 40 }` " +
          "failed with exit status #{ result.status }" ),
        status: result.status,
        stderr: result.err,
        stdout: result.out
    end # .from_result
    
  end # class Error
  
  
  class ManifestNotFoundError < Error; end
  

  # Class Methods
  # ========================================================================
  
  # @!group Utility Class Methods
  # --------------------------------------------------------------------------
  
  # Create a {Cmds} with formatting options defaulted for how (at least most)
  # `docker` subcommands seem to work.
  # 
  # @see https://www.rubydoc.info/gems/cmds
  # 
  # @param [String] exe:
  #   Docker executable to stick in front of `template`.
  # 
  # @param (see Cmds.new)
  # 
  # @return [Cmds]
  # 
  def self.cmd \
        template,
        exe: 'docker',
        array_mode: :repeat,
        dash_opt_names: true,
        hash_join_string: '=',
        long_opt_separator: ' ',
        **options
    Cmds.new \
      "#{ exe.shellescape } #{ template }",
      array_mode: array_mode,
      dash_opt_names: dash_opt_names,
      hash_join_string: hash_join_string,
      long_opt_separator: long_opt_separator,
      **options
  end # .cmd
  
  
  # Call {.cmd} with a template suitable for most `docker` subcommands.
  # 
  # Format is
  # 
  #     docker NAME [OPTS] [ARGS]
  # 
  # @see .cmd
  # 
  # @param [Array<#to_s>] *args
  #   Positional CLI arguments.
  # 
  # @param [Hash] **opts
  #   CLI options.
  # 
  # @return [Cmds]
  # 
  +QB::Util::Decorators::NoPropsInKwds
  def self.sub_cmd name, *args, **opts
    cmd \
      "<%= sub_cmd %> <%= opts %> <%= *args %>",
      args: args,
      kwds: {
        sub_cmd: name,
        opts: opts,
      }
  end # .sub_cmd
  
  # @!endgroup Utility Class Methods # ***************************************
  
  
  # @!group Sub-Command Class Methods
  # --------------------------------------------------------------------------
  
  # Build a `docker images` {Cmds} instance.
  # 
  # @param [Array<#to_s>] *args
  #   Specific image names to get.
  # 
  # @param [nil | Symbol | String] format:
  #   The `--format` option. Pass `nil` to use default formatting.
  # 
  # @param [Hash] **opts
  #   Other CLI options.
  # 
  # @return [Cmds]
  # 
  +QB::Util::Decorators::NoPropsInKwds
  def self.images_cmd *args, format: :raw, **opts
    sub_cmd :images, *args, format: format, **opts
  end # .images
  
  
  # Get a hash of image data from `docker images`.
  # 
  # @note
  #   If you just want the raw `docker images` output use:
  #   
  #       QB::Docker::CLI.images_cmd.out!
  # 
  # @param *args    (see .images_cmd)
  # @param format:  (see .images_cmd)
  # @param **opts   (see .images_cmd)
  # 
  # @param [Boolean] load:
  #   When `true`, will parse `created_at` to a {Time} and combine
  #   `repository` and `tag` to a {QB::Docker::Image::Name}.
  # 
  # @param [Boolean] only_named:
  #   Filter out images that don't have a name or tag.
  # 
  # @return [Array<HashWithIndifferentAccess>]
  #   Entry keys and values:
  #   
  #   -   `repository: String`
  #       
  #       Direct from command output, may be `"<none>"`.
  #       
  #   -   `tag: String`
  #       
  #       Direct from command output, may be `"<none>"`.
  #       
  #   -   `image_id: String`
  #       
  #       Short (12 character) image SHA256. Unless you pass the `--no-trunc`
  #       option, then it's the full `sha256:...` version.
  #       
  #   -   `created_at: String | Time`
  #       
  #       Time image was created (I think? Could be tag...)
  #       
  #       -   `String` if `load` keyword is `false`.
  #       -   `Time` if `load` keyword is `true`.
  #           
  #   -   `virtual_size: String`
  #       
  #       Direct from command output, like `"1.41GB"`.
  #       
  #   -   `name: void | QB::Docker::Image::Name`
  #       
  #       Combination of `repository` and `tag` parsed into a
  #       {QB::Docker::Image::Name}.
  #       
  #       Only present if `load` is `true` *and*
  #       
  # 
  +QB::Util::Decorators::NoPropsInKwds
  def self.images *args, load: true, only_named: true, **opts
    hashes = images_cmd( *args, **opts ).
      out!.
      split( "\n\n" ).
      map { |chunk|
        chunk.lines.map { |line|
            key, _, value = line.chomp.partition ': '
            
            if key == 'created_at'
              value = Time.parse value
            end
            
            [key, value]
          }.
          to_h.
          with_indifferent_access
      }
    
    if only_named
      hashes.reject! { |hash|
        hash.values_at( :repository, :tag ).any? { |v| v == '<none>' }
      }
    end
    
    if load
      hashes.each { |hash|
        values = hash.values_at :repository, :tag
        
        unless values.any? { |v| v == '<none>' }
          hash[:name] = QB::Docker::Image::Name.from_s values.join( ':' )
        end
      }
    end
    
    hashes
  end
  
  
  +QB::Util::Decorators::NoPropsInKwds
  def self.rmi_cmd *args, **opts
    sub_cmd :rmi, *args, **opts
  end
  
  singleton_class.send :alias_method, :remove_images_cmd, :rmi_cmd
  
  
  +QB::Util::Decorators::NoPropsInKwds
  def self.rmi *args, method: :stream!, **opts
    rmi_cmd( *args, **opts ).public_send method
  end
  
  singleton_class.send :alias_method, :remove_images, :rmi
  
    
  +QB::Util::Decorators::NoPropsInKwds
  def self.inspect_image_cmd *args, **opts
    sub_cmd :inspect, *args, **opts
  end
  
  
  +QB::Util::Decorators::NoPropsInKwds
  def self.inspect_image *names_or_ids, **opts
    inspect_cmd( *names_or_ids, **opts ).out!.thru { |s| JSON.load s }
  end
  
  
  +QB::Util::Decorators::NoPropsInKwds
  def self.pull_cmd *args, **opts
    sub_cmd :pull, *args, **opts
  end
  
  
  # Pull an image.
  # 
  # @param [String | QB::Docker::Image::Name] name
  # 
  +QB::Util::Decorators::NoPropsInKwds
  def self.pull name, **opts
    logger.info "Pulling #{ name }...",
      name: name.to_s,
      opts: opts
    
    result = pull_cmd( name, **opts ).capture
    
    if result.ok?
      logger.info "Successfully pulled #{ name }."
    else
      logger.info "Failed to pull #{ name }",
        stderr: result.err
    end
    
    result
  end
  
  
  +QB::Util::Decorators::NoPropsInKwds
  def self.push_cmd name, **opts
    sub_cmd :push, name, **opts
  end
  
  
  +QB::Util::Decorators::NoPropsInKwds
  def self.push name, **opts
    logger.info "Pushing `#{ name }`...", name: name, opts: opts
    
    result = push_cmd( name, **opts ).capture
  end
  
  
  +QB::Util::Decorators::NoPropsInKwds
  def self.build_cmd path_or_url, **opts
    sub_cmd :build, path_or_url, **opts
  end
  
  
  # +QB::Util::Decorators::NoPropsInKwds
  # def self.build path_or_url, **opts
  # 
  # end
  
  
  def self.tag_cmd current_name, new_name_or_tag
    # Load whatever we have
    current_name = QB::Docker::Image::Name.from current_name
    
    new_name_or_tag = [
      QB::Docker::Image::Name,
      QB::Docker::Image::Tag,
    ].try_find { |klass| klass.from new_name_or_tag }
    
    new_name = if new_name_or_tag.is_a?( QB::Docker::Image::Name )
      if new_name_or_tag.tag
        new_name_or_tag
      else
        new_name_or_tag.merge tag: current_name.tag
      end
    else
      current_name.merge tag: new_name_or_tag
    end
    
    sub_cmd :tag, current_name, new_name_or_tag
  end
  
  
  # @!endgroup Sub-Command Class Methods # ***********************************
  
  
  # @!group Sugar Class Methods
  # --------------------------------------------------------------------------
  # 
  # Making common shit easier.
  # 
  
  # Get just image names from `docker images`.
  # 
  # @param *args (see .images)
  # @return [Array<QB::Docker::Image::Name>]
  # 
  +QB::Util::Decorators::NoPropsInKwds
  def self.image_names *args, **opts
    images( *args, load: true, only_named: true, **opts ).
      map &:name.to_retriever
  end # .image_names
  
  
  # Is there an image with the name?
  # 
  # @param [QB::Docker::Image::Name | String] name
  # @return [Boolean]
  # 
  +QB::Util::Decorators::NoPropsInKwds
  def self.image_named? name, **opts
    !images( name, load: false, only_named: false, **opts ).empty?
  end
  
  
  # Boolean version of {.pull}.
  # 
  # @param name (see .pull)
  # 
  # @return [Boolean]
  #   `true` if the pull succeeded.
  # 
  +QB::Util::Decorators::NoPropsInKwds
  def self.pull? name, **opts
    pull( name, **opts ).ok?
  end


  # Pull an image by name or raise.
  # 
  # @param name (see .pull)
  # 
  # @todo
  #   Support `@DIGEST`
  # 
  # @raise [QB::Docker::CLI::ManifestNotFoundError]
  #   If the name was not found in the repository.
  # 
  # @raise [QB::Docker::CLI::Error]
  #   If anything else goes wrong.
  # 
  +QB::Util::Decorators::NoPropsInKwds
  def self.pull! name, **opts
    result = pull name, **opts
    
    if result.err =~ /manifest.*not\ found/
      raise QB::Docker::CLI::ManifestNotFoundError.new \
        "Failed to pull - manifest for #{ name } not found",
        name: name,
        cmd: result.cmd,
        stderr: result.err
    else
      raise QB::Docker::CLI::Error.from_result( result )
    end
  end
  
  # @!endgroup Sugar Class Methods # *****************************************
  
end; end; end # module QB::Docker::CLI
