require 'optparse'

require_relative "./role/errors"
require_relative './package/version'

require 'nrser/refinements/types'
using NRSER::Types


class QB::Options
  
  # Sub-Tree Requirements
  # ========================================================================
  
  require_relative './options/types'
  require_relative './options/option'
  
  
  # Constants
  # =======================================================================
  
  # Default initial values for {#qb}.
  # 
  # @return [Hash]
  # 
  QB_DEFAULTS = {
    'hosts' => ['localhost'].freeze,
    'facts' => true,
    'print' => [].freeze,
    'verbose' => false,
    'run' => true,
    'ask' => false,
  }.freeze
  
  
  # Appended on the end of an `opts.on` call to create a newline after
  # the option (making the help output a bit easier to read)
  # 
  # You might think the empty string would be reasonable, but OptionParser
  # blows up if you do that.
  # 
  # @return [String]
  # 
  SPACER = ' '
  
  
  # Mixins
  # ========================================================================
  
  include NRSER::Log::Mixin
  
  
  # Attributes
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
        raise QB::Role::MetadataError.new,
          "bad 'as' value: #{ include_meta.inspect }"
      end
    else
      include_path + [role.namespaceless]
    end
    
    QB.debug "including #{ role.name } as #{ new_include_path.join('-') }"
    
    opts.separator "Options for included #{ role.name } role:"
    
    add opts, options, role, new_include_path
  end
  
  
  # Add the options from a role to the OptionParser
  # 
  # @param [OptionParser] opts
  #   The option parser to add options to.
  # 
  def self.add opts, options, role, include_path = []
    QB.debug "adding options", "role" => role
    
    role.option_metas.each do |option_meta|
      if option_meta.key? 'include'
        include_role opts, options, option_meta, include_path
        
      else
        # create an option
        option = Option.new role, option_meta, include_path
        
        option.option_parser_add opts, included: !include_path.empty?
        
        options[option.cli_name] = option
      end
    end # each var
  end # add
  
  
  # Destructively removes options from `@argv` and populates ansible, role,
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
  
  
  # Constructor
  # =======================================================================
  
  # @param [Role] role
  #   the role to parse the args for.
  # 
  def initialize role, argv
    @role = role
    @argv = argv
    @qb = QB_DEFAULTS.dup
    
    parse!
  end
  
  
  # @todo Document ask? method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def ask?
    @qb['ask']
  end # #ask?
  
  
  
  private
  # =======================================================================
  
  # destructively removes options from `@argv` and populates ansible, role,
  # and qb option hashes.
  def parse!
    parse_ansible!
    
    @role_options = {}
    
    if @role.meta['default_user']
      @qb['user'] = @role.meta['default_user']
    end
    
    opt_parser = OptionParser.new do |opts|
      opts.accept(QB::Package::Version) do |string|
        QB::Package::Version.from( string ).to_h
      end
      
      opts.banner = @role.banner
      
      opts.separator "Common options:"
      
      opts.on(
        '-H',
        '--HOSTS=HOSTS',
        Array,
        "set playbook host",
        "DEFAULT: localhost",
        SPACER
      ) do |value|
        @qb['hosts'] = value
      end
      
      opts.on(
        '-I',
        '--INVENTORY=FILEPATH',
        String,
        "set inventory file",
        SPACER
      ) do |value|
        @qb['inventory'] = value
      end
      
      opts.on(
        '-U',
        '--USER=USER',
        String,
        "ansible become user for the playbook",
        SPACER
      ) do |value|
        @qb['user'] = value
      end
      
      opts.on(
        '-T',
        '--TAGS=TAGS',
        Array,
        "playbook tags",
        SPACER
      ) do |value|
        @qb['tags'] = value
      end
      
      opts.on(
        '-V[LEVEL]',
        "run playbook in verbose mode. use like -VVV or -V3.",
        SPACER
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
        SPACER
      ) do |value|
        @qb['facts'] = false
      end
      
      opts.on(
        '--PRINT=FLAGS',
        Array,
        "set what to print before running: options, env, cmd, playbook",
        SPACER
      ) do |value|
        @qb['print'] = value
      end
      
      opts.on(
        '--NO-RUN',
        "don't run the playbook (useful to just print stuff)",
        SPACER
      ) do |value|
        @qb['run'] = false
      end
      
      opts.on(
        '-A',
        '--ASK',
        "interactively ask for argument and option values",
        SPACER
      ) do |value|
        if value && !$stdin.isatty
          raise ArgumentError.squished <<-END
            Interactive args & options only works with TTY $stdin.
          END
        end
        
        @qb['ask'] = value
      end
      
      opts.separator "Role options:"
      
      self.class.add opts, @role_options, @role
      
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        
        @role.puts_examples
        
        exit
      end
    end
    
    opt_parser.parse! @argv
  end # parse!
  
  
  protected
  # ========================================================================
    
    # Pull options that start with
    #
    # 1.  `--ANSIBLE_`
    # 1.  `--ANSIBLE-`
    # 2.  `---`
    # 
    # out of `@argv` and stick them in `@ansible`.
    # 
    # @return [nil]
    #   **Mutates** `@argv`.
    # 
    def parse_ansible!
      logger.debug "Parsing Ansible options...",
        argv: @argv.dup
      
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
      
      nil
    end # #parse_ansible!
    
  # end protected
  
end # class QB::Options
