require 'yaml'
require 'cmds'

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
    
    # array of Pathname places to look for role dirs.
    def self.search_path
      [
        QB::ROLES_DIR,
        Pathname.new(Dir.getwd).join('roles'),
        Pathname.new(Dir.getwd).join('dev', 'roles'),
        Pathname.new(Dir.getwd).join('dev', 'roles', 'tmp'),
      ]
    end
    
    # array of QB::Role found in search path.
    def self.available
      search_path.
        select {|search_dir|
          # make sure it's there (and a direcotry)
          search_dir.directory?
        }.
        map {|search_dir|
          # grab all the child directories that are role directories
          search_dir.children.select {|child| role_dir? child }
        }.
        flatten.
        # needed when qb is run from the qb repo since QB::ROLES_DIR and
        # ./roles are the same dir
        uniq.
        map {|role_dir|
          QB::Role.new role_dir
        }
    end
    
    # get an array of QB::Role that match an input string
    def self.matches input
      available.each {|role|
        # exact match to relitive path
        return [role] if role.rel_path.to_s == input
      }.each {|role|
        # exact match to full name
        return [role] if role.name == input
      }.each {|role|
        # exact match without the namespace prefix ('qb.' or similar)
        return [role] if role.namespaceless == input
      }.select {|role|
        # select any that have that string in them
        role.rel_path.to_s.include? input
      }.tap {|matches|
        QB.debug "role matches" => matches
      }
    end
    
    # find exactly one matching role for the input string or raise.
    def self.require input
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
      meta['var_prefix'] || namespaceless
    end
    
    # get the options from the metadata, defaulting to [] if none defined
    def options
      meta['options'] || meta['opts'] || meta['vars'] || []
    end
    
    # old name
    alias_method :vars, :options
    
    # loads the defaults from defaults/main.yml, caching by default
    def load_defaults cache = true
      defaults_path = @path + 'defaults' + 'main.yml'
      defaults = if defaults_path.file?
        YAML.load(defaults_path.read) || {}
      else
        {}
      end
      
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
      if meta.key? 'save_options'
        !!meta['save_options']
      else
        true
      end
    end
  end
end