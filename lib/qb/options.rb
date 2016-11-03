require 'optparse'

require_relative "options/option"

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
      
      role.option_metas.each do |option_meta|
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
          
          on_args = [arg_style]
          # on_args = []
          
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
            when 'string', 'str'
              String
            when 'array', 'list'
              Array
            when 'integer', 'int'
              Integer
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
          
          if option.required?
            on_args << "REQUIRED."
          end
          
          if role.defaults.key? option.var_name
            on_args << if option.meta['type'] == 'boolean'
              if role.defaults[option.var_name]
                "DEFAULT: --#{ option.cli_name }"
              else
                "DEFAULT: --no-#{ option.cli_name }"
              end
            else
              "DEFAULT: #{ role.defaults[option.var_name] }"
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
        'hosts' => ['localhost'],
      }
      
      if role.meta['default_user']
        qb_options['user'] = role.meta['default_user']
      end
      
      opt_parser = OptionParser.new do |opts|
        opts.banner = role.banner
        
        opts.on(
          '-H',
          '--HOSTS=HOSTS',
          Array,
          "set playbook host",
          "DEFAULT: localhost"
        ) do |value|
          qb_options['hosts'] = value
        end
        
        opts.on(
          '-U',
          '--USER=USER',
          String,
          "ansible become user for the playbook"
        ) do |value|
          qb_options['user'] = value
        end
        
        opts.on(
          '-T',
          '--TAGS=TAGS',
          Array,
          "playbook tags",
        ) do |value|
          qb_options['tags'] = value
        end
        
        opts.on(
          '-V',
          '--VERBOSE[=LEVEL]',
          "run playbook in verbose mode"
        ) do |value|
          qb_options['verbose'] = if value.nil?
            1
          else
            value.to_i
          end
        end
      end
      
      opt_parser.parse! args
      
      [role_options, qb_options]
    end # parse!
  end # Options
end # QB