require 'nrser/refinements/types'

require_relative './types'

using NRSER::Types

class QB::Options::Option
  
  # Constants
  # ========================================================================
  
  EXAMPLES_KEYS = ['examples', 'example']
  
  
  # Mixins
  # ============================================================================
  
  include NRSER::Log::Mixin
  
  
  # Attributes
  # ========================================================================
  
  # the role that this option is for
  attr_reader :role
  
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
  
  
  
  # TODO document `type` attribute.
  # 
  # @return [attr_type]
  #     
  attr_reader :type
  
  
  
  # Construction
  # ======================================================================
  
  def initialize role, meta, include_path
    @role = role
    @meta = meta.with_indifferent_access
    @include_path = include_path
    
    @meta_name = meta.fetch 'name'
    
    @cli_name = if @include_path.empty?
      QB::Options.cli_ize_name @meta_name
    else
      QB::Options.cli_ize_name "#{ @include_path.join('-') }-#{ @meta_name }"
    end
    
    @var_name = if @meta['var_name']
      # prefer an explicit, exact variable name if provided
      @meta['var_name']
    elsif role.var_prefix
      QB::Options.var_ize_name "#{ role.var_prefix }_#{ @meta_name }"
    else
      QB::Options.var_ize_name @meta_name
    end
    
    @value = nil
    
    # Initialize `@type` var
    init_type!
  end
  
  protected
  # ========================================================================
    
    # Initialize `@type` to the {NRSER::Types::Type} loaded from the option
    # meta's `type` value.
    # 
    # @protected
    # 
    # @return [nil]
    # 
    def init_type!
      type_meta = meta[:type]
      
      if type_meta.nil?
        raise QB::Role::MetadataError.new \
          "Option", meta_name, "for role", role.name, "missing `type`",
          role_meta_path: role.meta_path,
          option_meta: meta
      end
      
      message = t.match type_meta,
        t.non_empty_str, ->( str ) {
          NRSER::Message.new str
        },
        
        t.pair( value: (t.hash_ | t.array) ), ->( pair ) {
          name, params = pair.first
          
          NRSER::Message.from( name, params ).symbolize_options
        }
      
      @type = [
        QB::Options::Types,
        t,
      ].find_map { |mod|
        if mod.respond_to? message.symbol
          begin
            type = message.send_to mod
          rescue Exception => error
            logger.warn "Type factory failed",
              { message: message },
              error
            
            nil
          else
            type if type.is_a?( t::Type )
          end
        end
      }
      
      if @type.nil?
        raise QB::Role::MetadataError.new \
          "Unable to find type factory for", type_meta,
          role_meta_path: role.meta_path,
          option_meta: meta,
          message: message
      end
      
    end # #init_type!
    
  public # end protected *****************************************************
  
  
  # Instance Methods
  # ========================================================================
  
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
    
    line_break = "\n" + "\t" * 5
      
    if @meta['type'].is_a?(Hash) && @meta['type'].key?('one_of')
      value += " options:" +
        "#{ line_break }#{ @meta['type']['one_of'].join(line_break) }"
    end
    
    value
  end
  
  def boolean?
    (
      meta['type'].is_a?(String) &&
      ['boolean', 'bool'].include?(meta['type'].downcase)
    )
  end
  
  def usage
    if boolean?
      "--[no-]#{ cli_name }"
    else
      "--#{ cli_name }=#{ meta_name.upcase }"
    end
  end
  
  # test if the option has any examples.
  # 
  # @return [Boolean]
  # 
  def has_examples?
    EXAMPLES_KEYS.any? {|key| meta.key? key}
  end
  
  # get an array of examples for the option. returns `[]` if no examples
  # are defined.
  # 
  # @return [Array<String>]
  # 
  def examples
    value = meta_or EXAMPLES_KEYS, []
    
    if value.is_a? String then [value] else value end
  end
  
  
  protected
  # ========================================================================
    
  # Get the value at the first found of the keys or the default.
  # 
  # `nil` (`null` in yaml files) are treated like they're not there at
  # all. you need to use `false` if you want to tell QB not to do something.
  # 
  def meta_or keys, default
    keys = [keys] if keys.is_a? String
    
    keys.map( &:to_s ).each do |key|
      if meta.key?(key) && !meta[key].nil?
        return meta[key]
      end
    end
    default
  end
    
  protected # end private ****************************************************
  
end # class QB::Options::Option
