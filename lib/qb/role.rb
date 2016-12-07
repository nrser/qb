require 'yaml'
require 'cmds'
require 'parseconfig'

module QB
  class Role
    attr_accessor :path, :name, :rel_path
    
    # errors
    # ======
    
    # base for errors in the module, extends QB:Error
    class Error < QB::Error
    end
    
    # raised by `.require` when no roles match input
    class NoMatchesError < Error
      attr_accessor :input
      
      def initialize input
        @input = input
        
        super "no roles match input #{ @input.inspect }"
      end
    end
    
    # rasied by `.require` when multiple roles match
    class MultipleMatchesError < Error
      attr_accessor :input, :matches
      
      def initialize input, matches
        @input = input
        @matches = matches
        
        super "mutiple roles match input #{ @input.inspect }:\n#{ @matches.join("\n") }"
      end
    end
    
    # static role utils
    # =================
    
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
        dir.join('roles', 'tmp')
      ]
    end
    
    # @return [Array<Pathname>] places to look for role dirs.
    def self.search_path
      [QB::ROLES_DIR] + [
        QB::Util.resolve,
        QB::Util.resolve('ansible'),
        QB::Util.resolve('dev'),
      ].map {|dir|
        roles_paths dir
      }.flatten
    end
    
    # array of QB::Role found in search path.
    def self.available
      search_path.
        select {|search_dir|
          # make sure it's there (and a directory)
          search_dir.directory?
        }.
        map {|search_dir|
          # grab all the child directories that are role directories
          search_dir.children.select {|child| role_dir? child }
        }.
        flatten.
        # should allow uniq to remove dups
        map {|role_dir| role_dir.realpath }.
        # needed when qb is run from the qb repo since QB::ROLES_DIR and
        # ./roles are the same dir
        uniq.
        map {|role_dir|
          QB::Role.new role_dir
        }
    end
    
    # get an array of QB::Role that match an input string
    def self.matches input
      available = self.available
      
      available.each {|role|
        # exact match to relative path
        return [role] if role.rel_path.to_s == input
      }.each {|role|
        # exact match to full name
        return [role] if role.name == input
      }.each {|role|
        # exact match without the namespace prefix ('qb.' or similar)
        return [role] if role.namespaceless == input
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
      
      # see if we word match any relative paths
      name_word_matches = available.select {|role|
        QB::Util.words_start_with? role.rel_path.to_s, input
      }
      return name_word_matches unless name_word_matches.empty?
      
      []
    end
    
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
          raise MetadataError.new,
            "bad 'as' value: #{ option_meta.inspect }"
        end
      else
        current_include_path + [role.namespaceless]
      end      
    end
    
    # instance methods
    # ================
    
    def initialize path
      @path = path
      
      @rel_path = if path.to_s.start_with? QB::ROLES_DIR.to_s
        path.sub(QB::ROLES_DIR.to_s + '/', '')
      elsif path.to_s.start_with? Dir.getwd
        path.sub(Dir.getwd + '/', './')
      else
        path
      end
      
      @name = path.to_s.split(File::SEPARATOR).last
    end
    
    def to_s
      @rel_path.to_s
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
      @rel_path.to_s
    end
    
    # load qb metadata from meta/qb.yml or from executing meta/qb and parsing
    # the YAML written to stdout.
    #
    # if `cache` is true caches it as `@meta`
    # 
    def load_meta cache = true
      meta = if (@path + 'meta' + 'qb').exist?
        YAML.load(Cmds.out!((@path + 'meta' + 'qb').realpath.to_s)) || {}
      elsif (@path + 'meta' + 'qb.yml').exist?
        YAML.load((@path + 'meta' + 'qb.yml').read) || {}
      else
        {}
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
    
    private
    
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