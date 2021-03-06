# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

### stdlib ###

require 'yaml'
require 'cmds'

### package ###

# Breakouts (things that are parts of {Role} but defined in separate files)
require_relative './role/errors'
require_relative './role/search_path'
require_relative './role/matches'
require_relative './role/name'
require_relative './role/default_dir'


# Namespace
# ========================================================================

module  QB


# Definitions
# ========================================================================

# Contains info on a QB role.
# 
class Role
  
  # Mixins
  # ============================================================================
  
  include SemanticLogger::Loggable
  
  
  # Class Methods
  # =======================================================================
  
  # true if pathname is a QB role directory.
  def self.role_dir? pathname
    # must be a directory
    pathname.directory? &&
    # and must have meta/qb.yml or meta/qb file
    ['qb.yml', 'qb'].any? {|filename| pathname.join('meta', filename).file?}
  end
  
  
  # All {QB::Role} found in search path.
  # 
  # Does it's best to remove duplicates that end up being reached though
  # multiple search paths (happens most in development).
  # 
  # @return [Array<QB::Role>]
  # 
  def self.available
    self.search_path.
      select {|search_dir|
        # make sure it's there (and a directory)
        search_dir.directory?
      }.
      map {|search_dir|
        ['', '.yml', '.yaml'].flat_map { |ext|
          Pathname.glob(search_dir.join '**', 'meta', "qb#{ ext }").
            map {|meta_path|
              [meta_path.dirname.dirname, search_dir: search_dir]
            }
        }
      }.
      flatten( 1 ).
      map { |args| QB::Role.new *args }.
      uniq
  end
  
  
  # Find exactly one matching role for the input string or raise.
  # 
  # Where we look is determined by {QB::Role::PATH} via {QB::Role.search_path}.
  # 
  # @param [String] input
  #   Input string term used to search (what we got off the CLI args).
  # 
  # @return [QB::Role]
  #   The single matching role.
  # 
  # @raise [QB::Role::NoMatchesError]
  #   If we didn't find any matches.
  # 
  # @raise [QB::Role::MultipleMatchesError]
  #   If we matched more than one role.
  # 
  def self.require input
    as_pathname = Pathname.new(input)
      
    # allow a path to a role dir
    if role_dir? as_pathname
      return QB::Role.new as_pathname
    end
    
    matches = self.matches input
    
    role = case matches.length
    when 0
      raise QB::Role::NoMatchesError.new input
    when 1
      matches[0]
    else
      raise QB::Role::MultipleMatchesError.new input, matches
    end
    
    QB.debug "role match" => role
    
    role
  end # .require
  
  
  # Get the include path for an included role based on the
  # option metadata that defines the include and the current
  # include path.
  # 
  # @param role [Role]
  #   the role to include.
  # 
  # @param option_meta [Hash]
  #   the entry for the option in qb.yml
  # 
  # @param current_include_path [Array<string>]
  # 
  # @return [Array<string>]
  #   include path for the included role.
  # 
  def self.get_include_path role, option_meta, current_include_path
    new_include_path = if option_meta.key? 'as'
      case option_meta['as']
      when nil, false
        # include it in with the parent role's options
        current_include_path
      when String
        current_include_path + [option_meta['as']]
      else
        raise QB::Role::MetadataError.new,
          "bad 'as' value: #{ option_meta.inspect }"
      end
    else
      current_include_path + [role.namespaceless]
    end
  end
  
  
  # The path we display in the CLI, see {#display_path}.
  # 
  # @param [Pathname | String] path
  #   input path to transform.
  # 
  # @return [Pathname]
  #   path to display.
  # 
  def self.to_display_path path
    if path.realpath.start_with? QB::GEM_ROLES_DIR
      path.realpath.sub (QB::GEM_ROLES_DIR.to_s + '/'), ''
    else
      QB::Util.contract_path path
    end
  end
  
  
  # Instance Attributes
  # =======================================================================
  
  # @!attribute [r] path
  #   @return [Pathname]
  #     location of the role directory.
  attr_reader :path
  
  
  # @!attribute [r] name
  #   @return [String]
  #     the role's ansible "name", which is it's directory name.
  attr_reader :name
  
  
  # @!attribute [r] display_path
  # 
  # the path to the role that we display. we only show the directory name
  # for QB roles, and use {QB::Util.compact_path} to show `.` and `~` for
  # paths relative to the current directory and home directory, respectively.
  # 
  #   @return [Pathname]
  attr_reader :display_path
  
  
  # @!attribute [r] meta_path
  #   @return [String, nil]
  #     the path qb metadata was load from. `nil` if it's never been loaded
  #     or doesn't exist.
  attr_reader :meta_path
  
  
  # Constructor
  # =======================================================================
  
  # Instantiate a Role.
  # 
  # @param [String|Pathname] path
  #   location of the role directory
  # 
  # @param [nil, Pathname] search_dir
  #   Directory in {QB::Role.search_path} that the role was found in.
  #   Used to figure out it's name correctly when using directory-structure
  #   namespacing.
  # 
  def initialize path, search_dir: nil
    @path = if path.is_a?(Pathname) then path else Pathname.new(path) end
    
    # check it...
    unless @path.exist?
      raise Errno::ENOENT.new @path.to_s
    end
    
    unless @path.directory?
      raise Errno::ENOTDIR.new @path.to_s
    end
    
    @display_path = self.class.to_display_path @path
    
    @meta_path = if (@path + 'meta' + 'qb').exist?
      @path + 'meta' + 'qb'
    elsif (@path + 'meta' + 'qb.yml').exist?
      @path + 'meta' + 'qb.yml'
    else
      raise Errno::ENOENT.new "#{ @path.join('meta').to_s }/[qb|qb.yml]"
    end
    
    
    if search_dir.nil?
      @name = @path.to_s.split(File::SEPARATOR).last
    else
      @name = @path.relative_path_from(search_dir).to_s
    end
  end # #initialize
  
  
  # Instance Methods
  # =====================================================================
  
  # Just a string version of {#display_path}
  # 
  def display_name
    display_path.to_s
  end
  
  
  def options_key
    display_name
  end
  
  # load qb metadata from meta/qb.yml or from executing meta/qb and parsing
  # the YAML written to stdout.
  #
  # if `cache` is true caches it as `@meta`
  # 
  def load_meta cache = true
    meta = if @meta_path.extname == '.yml'
      contents = begin
        @meta_path.read
      rescue Exception => error
        raise QB::Role::MetadataError,
          "Failed to read metadata file at #{ @meta_path.to_s }, " +
          "error: #{ error.inspect }"
      end
      
      begin
        YAML.load(contents) || {}
      rescue Exception => error
        raise QB::Role::MetadataError,
          "Failed to load metadata YAML from #{ @meta_path.to_s }, " +
          "error: #{ error.inspect }"
      end
    else
      YAML.load(Cmds.out!(@meta_path.realpath.to_s)) || {}
    end
    
    if cache
      @meta = meta
    end
    
    meta
  end
  
  # @return [Hash{String => Object}]
  #   the QB metadata for the role.
  # 
  def meta
    @meta || load_meta
  end
  
  
  # gets the variable prefix that will be appended to cli options before
  # passing them to the role. defaults to `#namespaceless` unless specified
  # in meta.
  def var_prefix
    # ugh, i was generating meta/qb.yml files that set 'var_prefix' to
    # `null`, but it would be nice to
    # 
    meta_or 'var_prefix', namespaceless
  end
  
  
  # get the options from the metadata, defaulting to [] if none defined
  def option_metas
    meta_or ['options', 'opts', 'vars'], []
  end
  
  
  # @return [Array<QB::Options::Option>
  #   an array of Option for the role, including any included roles.
  # 
  def options include_path = []
    option_metas.map {|option_meta|
      if option_meta.key? 'include'
        role_name = option_meta['include']
        role = QB::Role.require role_name
        role.options QB::Role.get_include_path(role, option_meta, include_path)
      else
        QB::Options::Option.new self, option_meta, include_path
      end
    }.flatten
  end # #options
  
  
  # loads the defaults from vars/main.yml and defaults/main.yml,
  # caching by default. vars override defaults values.
  def load_defaults cache = true
    defaults_path = @path + 'defaults' + 'main.yml'
    defaults = if defaults_path.file?
      YAML.load(defaults_path.read) || {}
    else
      {}
    end
    
    vars_path = @path + 'vars' + 'main.yml'
    vars = if vars_path.file?
      YAML.load(vars_path.read) || {}
    else
      {}
    end
    
    defaults = defaults.merge! vars
    
    if cache
      @defaults = defaults
    end
    
    defaults
  end
  
  # gets the role variable defaults from defaults/main.yml, or {}
  def defaults
    @defaults || load_defaults
  end
  
  def save_options
    !!meta_or('save_options', true)
  end
  
  # if the exe should auto-make the directory. this is nice for most roles
  # but some need it to be missing
  def mkdir
    !!meta_or('mkdir', true)
  end
  
  # @return [String]
  #   usage information formatted as plain text for the CLI.
  # 
  def usage
    # Split up options by required and optional.
    required_options = []
    optional_options = []
    
    options.each { |option|
      if option.required?
        required_options << option
      else
        optional_options << option
      end
    }
    
    parts = ['qb [run]', name]
    
    required_options.each { |option|
      parts << option.usage
    }
    
    unless optional_options.empty?
      parts << '[OPTIONS]'
    end
    
    if has_dir_arg?
      parts << 'DIRECTORY'
    end
    
    parts.join ' '
  end
  
  
  # get the CLI banner for the role
  def banner
    lines = []
    
    name_line = "#{ name } role"
    lines << name_line
    lines << "=" * name_line.length
    lines << ''
    if meta['description']
      lines << meta['description']
      lines << ''
    end
    lines << 'Usage:'
    lines << ''
    lines << "  #{ usage }"
    lines << ''
    lines << ''
    
    lines.join("\n")
  end
  
  
  def examples
    @meta['examples']
  end
  
  # format the `meta.examples` hash into a string suitable for cli
  # output.
  # 
  # @return [String]
  #   the CLI-formatted examples.
  # 
  def format_examples
    examples.
      map {|title, body|
        [
          "#{ title }:",
          body.lines.map {|l|
            # only indent non-empty lines
            # makes compacting newline sequences easier (see below)
            if l.match(/^\s*$/)
              l
            else
              '  ' + l
            end
          },
          ''
        ]
      }.
      flatten.
      join("\n").
      # compact newline sequences
      gsub(/\n\n+/, "\n\n")
  end
  
  # examples text
  def puts_examples
    return unless examples
    
    puts "\n" + format_examples + "\n"
  end
  
  # should qb ask for an ansible vault password?
  # 
  # @see http://docs.ansible.com/ansible/playbooks_vault.html
  # 
  # @return [Boolean]
  #   `true` if qb should ask for a vault password.
  # 
  def ask_vault_pass?
    !!@meta['ask_vault_pass']
  end
  
  
  # Test if the {QB::Role} uses a directory argument (that gets assigned to
  # the `qb_dir` variable in Ansible).
  # 
  # @return [Boolean]
  # 
  def has_dir_arg?
    meta['default_dir'] != false
  end # #has_dir_arg?
  
  
  # @return [Hash<String, *>]
  #   default `ansible-playbook` CLI options from role qb metadata.
  #   Hash of option name to value.
  def default_ansible_options
    meta_or 'ansible_options', {}
  end
  
  
  # Parsed tree structure of version requirements of the role from the
  # `requirements` value in the QB meta data.
  # 
  # @return [Hash]
  #   Tree where the leaves are {Gem::Requirement}.
  # 
  def requirements
    @requirements ||= NRSER.map_leaves(
      meta_or 'requirements', {'gems' => {}}
    ) { |key_path, req_str|
      Gem::Requirement.new req_str
    }
  end # #requirements
  
  
  # Check the role's requirements.
  # 
  # @return [nil]
  # 
  # @raise [QB::AnsibleVersionError]
  #   If the version of Ansible found does not satisfy the role's requirements.
  # 
  # @raise [QB::QBVersionError]
  #   If the the version of QB we're running does not satisfy the role's
  #   requirements.
  # 
  def check_requirements
    if ansible_req = requirements['ansible']
      unless ansible_req.satisfied_by? QB.ansible_version
        raise QB::AnsibleVersionError.squished <<-END
          QB #{ QB::VERSION } requires Ansible #{ ansible_req },
          found version #{ QB.ansible_version  } at #{ `which ansible` }
        END
      end
    end
    
    if qb_req = requirements.dig( 'gems', 'qb' )
      unless qb_req.satisfied_by? QB.gem_version
        raise QB::QBVersionError.squished <<-END
          Role #{ self } requires QB #{ qb_req },
          using QB #{ QB.gem_version } from #{ QB::ROOT }.
        END
      end
    end
    
    nil
  end # #check_requirements
  
  
  # @return [String]
  #   The `description` value from the role's QB metadata, or '' if it doesn't
  #   have one
  def description
    meta['description'].to_s
  end
  
  
  # Short summary pulled from the role description - first line if it's
  # multi-line, or first sentence if it's a single line.
  # 
  # Will be an empty string if the role doesn't have a description.
  # 
  # @return [String]
  # 
  def summary
    description.lines.first.thru { |line|
      if line
        line.split( '. ', 2 ).first
      else
        ''
      end
    }
  end
  
  
  # Language Inter-Op
  # -----------------------------------------------------------------------
  
  def hash
    path.realpath.hash
  end
  
  
  def == other
    other.is_a?(self.class) && other.path.realpath == path.realpath
  end
  
  alias_method :eql?, :==
  
  
  # @return [String]
  #   {QB::Role#display_path}
  # 
  def to_s
    @display_path.to_s
  end
  
  
  private
  # -----------------------------------------------------------------------
  
    # get the value at the first found of the keys or the default.
    # 
    # `nil` (`null` in yaml files) are treated like they're not there at
    # all. you need to use `false` if you want to tell QB not to do something.
    # 
    # @param [String | Symbol | Array<String | Symbol>] keys
    #   Single
    # 
    # @return [Object]
    # 
    def meta_or keys, default
      keys.as_array.map(&:to_s).each do |key|
        return meta[key] unless meta[key].nil?
      end
      
      # We didn't find anything (that wasn't explicitly or implicitly `nil`)
      default
    end # meta_or
    
    
    # Find a non-null/nil value for one of `keys` or raise an error.
    # 
    # @param [String | Symbol | Array<String | Symbol>] keys
    #   Possible key names. They will be searched in order and first
    #   non-null/nil value returned.
    # 
    # @return [Object]
    # 
    # @raise [QB::Role::MetadataError]
    #   If none of `keys` are found.
    # 
    def need_meta keys
      keys = keys.as_array.map(&:to_s)
      
      keys.each do |key|
        return meta[key] unless meta[key].nil?
      end
      
      raise QB::Role::MetadataError.squished <<-END
        Expected metadata for role #{ self } to define (non-null) value for
        one of keys #{ keys.inspect }.
      END
    end # need_meta
    
    
  # end private
  
end # class Role


# /Namespace
# ========================================================================

end # module QB
