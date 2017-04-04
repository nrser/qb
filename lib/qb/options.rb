require 'optparse'

require_relative "options/errors"
require_relative "options/option"

module QB
  class Options
    # constants
    # =======================================================================
    
    QB_DEFAULTS = {
      'hosts' => ['localhost'],
      'facts' => true,
      'print' => ['env', 'cmd'],
      'verbose' => false,
      'run' => true,
    }
    
    # attributes
    # =======================================================================
    
    # @!attribute [r] ansible
    #   @return [Hash<String, String>]
    #     options to pass through to ansible-playbook.
    attr_reader :ansible
    
    # @!attribute [r] role_options
    #   @return [Hash<String, QB::Options::Option>]
    #     options to pass through to ansible-playbook.
    attr_reader :role_options
    
    # @!attribute [r] qb
    #   @return [Hash<String, *>]
    #     common qb-level options.
    attr_reader :qb
    
    # class methods
    # =======================================================================

    # turn a name into a "command line" version by replacing underscores with
    # dashes.
    # 
    # @param [String] option_name
    #   the input option name.
    # 
    # @return [String]
    #   the CLI-ized name.
    # 
    # @example
    #   QB::Options.cli_ize_name "my_var" # => "my-var"
    # 
    def self.cli_ize_name option_name
      option_name.gsub '_', '-'
    end
    
    # turn a name into a "ruby / ansible variable" version by replacing
    # dashes with underscores.
    # 
    # @param [String] option_name
    #   the input option name.
    # 
    # @return [String]
    #   the ruby / ansible var-ized name.
    # 
    # @example
    #   QB::Options.cli_ize_name "my-var" # => "my_var"
    # 
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
          raise QB::Options::MetadataError.new,
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
              raise QB::Options::MetadataError,
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
                    raise QB::Options::MetadataError,
                      "option '#{ option.cli_name }' must be one of: #{ option.meta['type']['one_of'].join(', ') }"
                  end
                }
                klass
              else 
                raise QB::Options::MetadataError,
                  "bad type for option #{ option.meta_name }: #{ option.meta['type'].inspect }"
              end
            else
              raise QB::Options::MetadataError,
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
            if option.meta['type'] == 'boolean'
              on_args << if role.defaults[option.var_name]
                "DEFAULT: --#{ option.cli_name }"
              else
                "DEFAULT: --no-#{ option.cli_name }"
              end
            elsif !role.defaults[option.var_name].nil?
              on_args << "DEFAULT: #{ role.defaults[option.var_name] }"
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
    
    # destructively removes options from `@argv` and populates ansible, role,
    # and qb option hashes.
    # 
    # @param [QB::Role] role
    #   the role to parse the options for.
    # 
    # @param [Array<String>] args
    #   CLI args -- `ARGV` with the role arg shifted off.
    # 
    # @return [Array<Hash<String, Option|Object>>]
    #   a two-element array:
    #   
    #   1.  the options for the role, hash of Option#cli_name to Option
    #       instances.
    #       
    #   2.  the general qb options, hash of String key to option values.
    #   
    # @raise if bad options are found.
    # 
    def self.parse! role, argv
      options = self.new role, argv
      [options.role_options, options.qb]
    end
    
    # constructor
    # =======================================================================
    
    # @param [Role] role
    #   the role to parse the args for.
    # 
    def initialize role, argv
      @role = role
      @argv = argv
      
      parse!
    end
    
    private
    # =======================================================================
    
    # destructively removes options from `@argv` and populates ansible, role,
    # and qb option hashes.
    def parse!
      parse_ansible!
      
      @role_options = {}
      
      @qb = QB_DEFAULTS.clone
      
      if @role.meta['default_user']
        @qb['user'] = @role.meta['default_user']
      end
      
      opt_parser = OptionParser.new do |opts|
        opts.banner = @role.banner
        
        opts.on(
          '-H',
          '--HOSTS=HOSTS',
          Array,
          "set playbook host",
          "DEFAULT: localhost"
        ) do |value|
          @qb['hosts'] = value
        end
        
        opts.on(
          '-I',
          '--INVENTORY=FILEPATH',
          String,
          "set inventory file",
        ) do |value|
          @qb['inventory'] = value
        end
        
        opts.on(
          '-U',
          '--USER=USER',
          String,
          "ansible become user for the playbook"
        ) do |value|
          @qb['user'] = value
        end
        
        opts.on(
          '-T',
          '--TAGS=TAGS',
          Array,
          "playbook tags",
        ) do |value|
          @qb['tags'] = value
        end
        
        opts.on(
          '-V[LEVEL]',
          "run playbook in verbose mode. use like -VVV or -V3."
        ) do |value|
          # QB.debug "verbose", value: value
          
          @qb['verbose'] = if value.nil?
            1
          else
            case value
            when '0'
              false
            when /^[1-4]$/
              value.to_i
            when /^[V]{1,3}$/i
              value.length + 1
            else
              raise "bad verbose value: #{ value.inspect }"
            end
          end
        end
        
        opts.on(
          '--NO-FACTS',
          "don't gather facts",
        ) do |value|
          @qb['facts'] = false
        end
        
        opts.on(
          '--PRINT=FLAGS',
          Array,
          "set what to print before running."
        ) do |value|
          @qb['print'] = value
        end
        
        opts.on(
          '--NO-RUN',
          "don't run the playbook (useful to just print stuff)",
        ) do |value|
          @qb['run'] = false
        end
        
        self.class.add opts, @role_options, @role
        
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          
          @role.puts_examples
          
          exit
        end
      end
      
      opt_parser.parse! @argv
    end # parse!
    
    # pull options that start with
    #
    # 1.  `--ANSIBLE_`
    # 1.  `--ANSIBLE-`
    # 2.  `---`
    # 
    # out of `@argv` and stick them in `@ansible`.
    def parse_ansible!
      @ansible = @role.default_ansible_options.clone
      
      reg_exs = [
        /\A\-\-ANSIBLE[\-\_]/,
        /\A\-\-\-/,
      ]
      
      @argv.reject! {|shellword|
        if re = reg_exs.find {|re| re =~ shellword}
          name = shellword.sub re, ''
          
          value = true
          
          if name.include? '='
            name, value = name.split('=', 2)
          end
          
          @ansible[name] = value
          
          true
        end
      }
    end # #parse_ansible!
    
  end # Options
end # QB