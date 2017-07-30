require 'yaml'
require 'cmds'
require 'parseconfig'
require 'nrser/refinements'

require_relative 'role/errors'

using NRSER

module QB
  # contains info on a QB role.
  # 
  # 
  class Role
    # attrs
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

    
    # static role utils
    # =======================================================================
    
    # true if pathname is a QB role directory.
    def self.role_dir? pathname
      # must be a directory
      pathname.directory? &&
      # and must have meta/qb.yml or meta/qb file
      ['qb.yml', 'qb'].any? {|filename| pathname.join('meta', filename).file?}
    end
    
    # get role paths from ansible.cfg if it exists in a directory.
    # 
    # @param dir [Pathname] directory to look for ansible.cfg in.
    # 
    # @return [Array<String>] role paths
    # 
    def self.cfg_roles_path dir
      path = dir.join 'ansible.cfg'
      
      if path.file?
        config = ParseConfig.new path.to_s
        config['defaults']['roles_path'].split(':').map {|path|
          QB::Util.resolve dir, path
        }
      else
        []
      end
    end
    
    # @param dir [Pathname] dir to include.
    def self.roles_paths dir
      cfg_roles_path(dir) + [
        dir.join('roles'),
        dir.join('roles', 'tmp'),
      ]
    end
    
    # places to look for qb role directories. these paths are also included
    # when qb runs a playbook.
    # 
    # TODO resolution order:
    # 
    # 1.  paths specific to this run:
    #     a.  TODO paths provided on the cli.
    # 2.  paths specific to the current directory:
    #     a.  paths specified in ./ansible.cfg (if it exists)
    #     b.  ./roles
    #     c.  ./roles/tmp
    #         -   used for roles that are downloaded but shouldn't be included
    #             in source control.
    #     d.  paths specified in ./ansible/ansible.cfg (if it exists)
    #     e.  ./ansible/roles
    #     f.  ./ansible/roles/tmp
    #         -   used for roles that are downloaded but shouldn't be included
    #             in source control.
    #     g.  paths specified in ./dev/ansible.cfg (if it exists)
    #     h.  ./dev/roles
    #     i.  ./dev/roles/tmp
    #         -   used for roles that are downloaded but shouldn't be included
    #             in source control.
    # 3.  
    # 
    # @return [Array<Pathname>]
    #   places to look for role dirs.
    # 
    def self.search_path
      [
        QB::USER_ROLES_DIR,
        QB::GEM_ROLES_DIR
      ] + [
        QB::Util.resolve,
        QB::Util.resolve('ansible'),
        QB::Util.resolve('dev'),
      ].map {|dir|
        roles_paths dir
      }.
      flatten
    end
    
    # array of QB::Role found in search path.
    def self.available
      # search_path.
      #   select {|search_dir|
      #     # make sure it's there (and a directory)
      #     search_dir.directory?
      #   }.
      #   map {|search_dir|
      #     # grab all the child directories that are role directories
      #     search_dir.children.select {|child| role_dir? child }
      #   }.
      #   flatten.
      #   map {|role_dir|
      #     QB::Role.new role_dir
      #   }.
      #   uniq
      
      search_path.
        select {|search_dir|
          # make sure it's there (and a directory)
          search_dir.directory?
        }.
        map {|search_dir|
          Pathname.glob(search_dir.join '**', 'meta', 'qb.yml').
            map {|meta_path|
              meta_path.dirname.dirname
            }
        }.
        flatten.
        map {|role_dir|
          QB::Role.new role_dir
        }.
        uniq
    end
    
    # get an array of QB::Role that match an input string
    def self.matches input
      # keep this here to we don't re-gen every loop
      available = self.available
      
      # first off, see if input matches any relative paths exactly
      available.each {|role|
        return [role] if role.display_path.to_s == input
      }
      
      # create an array of "separator" variations to try *exact* matching 
      # against. in order of preference:
      # 
      # 1.  exact input
      #     -   this means if you ended up with roles that actually *are*
      #         differnetiated by '_/-' differences (which, IMHO, is a 
      #         horrible fucking idea), you can get exactly what you ask for
      #         as a first priority
      # 2.  input with '-' changed to '_'
      #     -   prioritized because convetion is to underscore-separate
      #         role names.
      # 3.  input with '_' changed to '-'
      #     -   really just for convience's sake so you don't really have to 
      #         remember what separator is used.
      #     
      separator_variations = [
        input,
        input.gsub('-', '_'),
        input.gsub('_', '_'),
      ]
      
      separator_variations.each {|variation|
        available.each {|role|
          # exact match to full name
          return [role] if role.name == variation
        }.each {|role|
          # exact match without the namespace prefix ('qb.' or similar)
          return [role] if role.namespaceless == variation
        }  
      }
      
      # see if we prefix match any full names
      name_prefix_matches = available.select {|role|
        role.name.start_with? input
      }
      return name_prefix_matches unless name_prefix_matches.empty?
      
      # see if we prefix match any name
      namespaceless_prefix_matches = available.select {|role|
        role.namespaceless.start_with? input
      }
      unless namespaceless_prefix_matches.empty?
        return namespaceless_prefix_matches 
      end
      
      # see if we prefix match any display paths
      path_prefix_matches = available.select {|role|
        role.display_path.start_with? input
      }
      return path_prefix_matches unless path_prefix_matches.empty?
      
      # see if we word match any display` paths
      name_word_matches = available.select {|role|
        QB::Util.words_start_with? role.display_path.to_s, input
      }
      return name_word_matches unless name_word_matches.empty?
      
      # nada
      []
    end # .matches
    
    # find exactly one matching role for the input string or raise.
    def self.require input
      
      as_pathname = Pathname.new(input)
        
      # allow a path to a role dir
      if role_dir? as_pathname
        return Role.new as_pathname
      end
      
      matches = self.matches input
      
      role = case matches.length
      when 0
        raise NoMatchesError.new input
      when 1
        matches[0]
      else
        raise MultipleMatchesError.new input, matches
      end
      
      QB.debug "role match" => role
      
      role
    end
    
    # get the include path for an included role based on the 
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
    
    # the path we display in the CLI, see {#display_path}.
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
    
    # instance methods
    # =======================================================================
    
    # 
    # @param [String|Pathname] path
    #   location of the role directory
    # 
    def initialize path
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
      
      @name = @path.to_s.split(File::SEPARATOR).last
    end
    
    def to_s
      @display_path.to_s
    end
    
    def namespace
      if @name.include? '.'
        @name.split('.').first
      else
        nil
      end
    end
    
    def namespaceless
      @name.split('.', 2).last
    end
    
    def options_key
      @display_path.to_s
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
    
    # gets the qb metadata for the role
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
    
    # get an array of Option for the role, including any included roles
    def options include_path = []
      option_metas.map {|option_meta|
        if option_meta.key? 'include'
          role_name = option_meta['include']
          role = QB::Role.require role_name
          role.options Role.get_include_path(role, option_meta, include_path)
        else
          QB::Options::Option.new self, option_meta, include_path
        end
      }.flatten
    end
    
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
    
    def usage
      parts = ['qb', name]
      options.each {|option|
        if option.required?
          parts << option.usage
        end
      }
      parts << '[OPTIONS] DIRECTORY'
      parts.join(' ')
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
      lines << 'usage:'
      # lines << "  qb #{ name } [OPTIONS] DIRECTORY"
      lines << "  #{ usage }"
      lines << ''
      lines << 'options:'
      
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
    
    # gets the default `qb_dir` value, raising an error if the role doesn't
    # define how to get one or there is a problem getting it.
    # 
    # 
    def default_dir cwd, options
      QB.debug "get_default_dir",  role: self,
                                meta: self.meta,
                                cwd: cwd,
                                options: options
      
      key = 'default_dir'
      value = self.meta[key]
      case value
      when nil
        # there is no get_dir info in meta/qb.yml, can't get the dir
        raise <<-END.dedent
          unable to infer default directory: no '#{ key }' key in 'meta/qb.yml'
          for role #{ self }
        END
      
      when false
        # this method should not get called when the value is false (an entire
        # section is skipped in exe/qb when `default_dir = false`)
        raise "role does not use default directory (meta/qb.yml:default_dir = false)"
      
      when 'git_root'
        QB.debug "returning the git root relative to cwd"
        NRSER.git_root cwd
      
      when 'cwd'
        QB.debug "returning current working directory"
        cwd
        
      when Hash
        QB.debug "qb meta option is a Hash"
        
        unless value.length == 1
          raise "#{ meta_path.to_s }:default_dir invalid: #{ value.inspect }"
        end
        
        hash_key, hash_value = value.first
        
        case hash_key
        when 'exe'
          exe_path = hash_value
          
          # supply the options to the exe so it can make work off those values
          # if it wants.
          exe_input_data = Hash[
            options.map {|option|
              [option.cli_option_name, option.value]
            }
          ]
          
          unless exe_path.start_with?('~') || exe_path.start_with?('/')
            exe_path = File.join(self.path, exe_path)
            debug 'exe path is relative, basing off role dir', exe_path: exe_path
          end
          
          debug "found 'exe' key, calling", exe_path: exe_path,
                                            exe_input_data: exe_input_data
          
          Cmds.chomp! exe_path do
            JSON.dump exe_input_data
          end
          
        when 'find_up'
          filename = hash_value
          
          unless filename.is_a? String
            raise "find_up filename must be string, found #{ filename.inspect }"
          end
          
          QB.debug "found 'find_up', looking for file named #{ filename }"
          
          QB::Util.find_up filename
          
        else
          raise "bad key: #{ hash_key } in #{ self.meta_path.to_s }:default_dir"
          
        end
      end
    end # default_dir
    
    # @return [Hash<String, *>]
    #   default `ansible-playbook` CLI options from role qb metadata.
    #   Hash of option name to value.
    def default_ansible_options
      meta_or 'ansible_options', {}
    end
    
    
    # Get the {Gem::Requirement} parse of the `qb_requirement` key in
    # {#meta} (if it is defined), which specifies the required version of 
    # `qb` for the role.
    # 
    # @return [Gem::Requirement, nil]
    #   The requirement if `required_qb_version` key is in {#meta}, else `nil`.
    # 
    def qb_requirement
      if  meta['requirements'] &&
          meta['requirements']['gems'] &&
          meta['requirements']['gems']['qb']
        Gem::Requirement.new meta['requirements']['gems']['qb']
      end
    end
    
    
    # language inter-op
    # -----------------------------------------------------------------------
    
    def hash
      path.realpath.hash
    end
    
    def == other
      other.is_a?(Role) && other.path.realpath == path.realpath
    end
    
    alias_method :eql?, :==
    
    private
    # -----------------------------------------------------------------------
    
    # get the value at the first found of the keys or the default.
    # 
    # `nil` (`null` in yaml files) are treated like they're not there at
    # all. you need to use `false` if you want to tell QB not to do something.
    # 
    def meta_or keys, default
      keys = [keys] if keys.is_a? String
      keys.each do |key|
        if meta.key?(key) && !meta[key].nil?
          return meta[key]
        end
      end
      default
    end # meta_or
  end # Role
end # QB