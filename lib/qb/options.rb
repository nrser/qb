require 'optparse'
require 'weakref'

module QB
  module Options
    # errors
    # ======
    
    # base for errors in the module, extends QB:Error
    class Error < QB::Error
    end
    
    # raised when an included role includes another, which we don't support
    # (for now)
    class NestedIncludeError < Error
      def initialize
        super "can't nest role includes"
      end
    end
    
    # raised when there's bad option metadata 
    class MetadataError < Error
    end
    
    def self.cli_ize_name option_name
      option_name.gsub '_', '-'
    end
    
    def self.var_ize_name option_name
      option_name.gsub '-', '_'
    end
    
    # 
    class Option
      # the role that this option is for
      # attr_reader :role
      
      # the entry from the qb metadata for this option
      attr_reader :meta
      
      # array of strings representing how this option was included
      # empty for top-level options
      attr_reader :include_path
      
      # the name of the option in the qb metadata, equal to #meta['name']
      attr_reader :meta_name
      
      # the name that this option will be available in the cli as
      attr_reader :cli_name
      
      # the name that the value will be passed to ansible as
      attr_reader :var_name
      
      # the value of the option, or `nil` if we never assign one
      attr_accessor :value
      
      def initialize role, meta, include_path
        # @role = WeakRef.new role
        @meta = meta
        @include_path = include_path
        
        @meta_name = meta.fetch 'name'
        
        @cli_name = if @include_path.empty?
          Options.cli_ize_name @meta_name
        else
          Options.cli_ize_name "#{ @include_path.join('-') }-#{ @meta_name }"
        end
        
        @var_name = if role.var_prefix
          Options.var_ize_name "#{ role.var_prefix }_#{ @meta_name }"
        else
          Options.var_ize_name @meta_name
        end
        
        @value = nil
      end
      
      # if the option is required in the cli
      def required?
        !!meta_or(['required', 'require'], false)
      end
      
      # if we should save the option value in .qb-options.yml
      def save?
        !!meta_or('save', true)
      end
      
      def description
        value = meta_or 'description',
          "set the #{ @var_name } role variable"
          
        if @meta['type'].is_a?(Hash) && @meta['type'].key?('one_of')
          line_break = "\n" + "\t" * 5
          value += " options:" + 
            "#{ line_break }#{ @meta['type']['one_of'].join(line_break) }"
        end
        
        value
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
      end
      
    end # Option
    
    def self.include_role opts, options, include_meta, include_path
      role_name = include_meta['include']
      role = QB::Role.require role_name
      new_include_path = if include_meta.key? 'as'
        case include_meta['as']
        when nil, false
          # include it in with the parent role's options
          include_path
        when String
          include_path + [include_meta['as']]
        else
          raise MetadataError.new,
            "bad 'as' value: #{ include_meta.inspect }"
        end
      else
        include_path + [role.namespaceless]
      end
      
      QB.debug "including #{ role.name } as #{ new_include_path.join('-') }"
      
      add opts, options, role, new_include_path
    end
    
    # add the options from a role to the OptionParser
    def self.add opts, options, role, include_path = []
      QB.debug "adding options", "role" => role
      
      role.options.each do |option_meta|
        if option_meta.key? 'include'
          include_role opts, options, option_meta, include_path
          
        else
          # create an option
          option = Option.new role, option_meta, include_path
          
          arg_style = if option.required?
            :REQUIRED
          else
            :OPTIONAL
          end
          
          # on_args = [arg_style]
          on_args = []
          
          if option.meta['type'] == 'boolean'
            # don't use short names when included (for now)
            if include_path.empty? && option.meta['short']
              on_args << "-#{ option.meta['short'] }"
            end
            
            on_args << "--[no-]#{ option.cli_name }"
            
          else
            ruby_type = case option.meta['type']
            when nil
              raise MetadataError,
                "must provide type in qb metadata for option #{ option.meta_name }"
            when 'string'
              String
            when Hash
              if option.meta['type'].key? 'one_of'
                klass = Class.new
                opts.accept(klass) {|value|
                  if option.meta['type']['one_of'].include? value
                    value
                  else
                    raise MetadataError,
                      "option '#{ option.cli_name }' must be one of: #{ option.meta['type']['one_of'].join(', ') }"
                  end
                }
                klass
              else 
                raise MetadataError,
                  "bad type for option #{ option.meta_name }: #{ option.meta['type'].inspect }"
              end
            else
              raise MetadataError,
                "bad type for option #{ option.meta_name }: #{ option.meta['type'].inspect }"
            end
            
            # don't use short names when included (for now)
            if include_path.empty? && option.meta['short']
              on_args << "-#{ option.meta['short'] } #{ option.meta_name.upcase }"
            end
            
            if option.meta['accept_false']
              on_args << "--[no-]#{ option.cli_name }=#{ option.meta_name.upcase }"
            else
              on_args << "--#{ option.cli_name }=#{ option.meta_name.upcase }"
            end
              
            
            on_args << ruby_type
          end
          
          on_args << option.description
          
          if role.defaults.key? option.var_name
            on_args << if option.meta['type'] == 'boolean'
              if role.defaults[option.var_name]
                "default --#{ option.cli_name }"
              else
                "default --no-#{ option.cli_name }"
              end
            else
              "default = #{ role.defaults[option.var_name] }"
            end
          end
          
          QB.debug "adding option", option: option, on_args: on_args
          
          opts.on(*on_args) do |value|
            QB.debug  "setting option",
                      option: option,
                      value: value
            
            option.value = value
          end
          
          options[option.cli_name] = option
        end
      end # each var
    end # add 
    
    def self.parse! role, args      
      role_options = {}
      
      qb_options = {
        'host' => 'localhost',
      }
      
      opt_parser = OptionParser.new do |opts|
        opts.banner = role.banner
        
        opts.on(
          '-H',
          '---host=HOST',
          "set playbook host",
          "default: localhost"
        ) do |value|
          qb_options['host'] = value
        end
        
        add opts, role_options, role
        
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end
      
      opt_parser.parse! args
      
      [role_options, qb_options]
    end # parse!
  end # Options
end # QB