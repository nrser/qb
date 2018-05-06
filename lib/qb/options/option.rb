# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# ========================================================================

# Deps
# ------------------------------------------------------------------------

# Need {Module#concerning}
require 'active_support/core_ext/module/concerning'

# Project / Package
# ------------------------------------------------------------------------

# Need additional {QB::Options::Types} for option type loading
require_relative './types'

# Need {OptionParserConcern} to handle fucking {OptionParser} :(
require_relative './option/option_parser_concern'


# Refinements
# ========================================================================

require 'nrser/refinements/types'
using NRSER::Types

require 'nrser/refinements/sugar'
using NRSER::Sugar


# Namespace
# ============================================================================

module  QB
class   Options


# Definitions
# ========================================================================

class Option
  
  # Constants
  # ========================================================================
  
  EXAMPLES_KEYS = ['examples', 'example']
  
  
  # Mixins
  # ============================================================================
  
  include NRSER::Log::Mixin
  
  include OptionParserConcern
  
  
  # Attributes
  # ========================================================================
  
  # the role that this option is for
  attr_reader :role
  
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
    
    @var_name = if self.meta?( :var_name )
      # prefer an explicit, exact variable name if provided
      self.meta( :var_name, type: Types.var_name )
    elsif role.var_prefix
      QB::Options.var_ize_name "#{ role.var_prefix }_#{ meta_name }"
    else
      QB::Options.var_ize_name meta_name
    end
    
    # Will be set when we find it out!
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
      
      if  t.non_empty_str === type_meta &&
          type_meta.include?( '::' )
        
        const = type_meta.safe_constantize
        
        if  const &&
            const.is_a?( Class ) &&
            ( const < NRSER::Types::Type ||
              const < NRSER::Props )
          @type = const
          return
        end
        
      end
      
      message = t.match type_meta,
        t.non_empty_str, ->( str ) {
          NRSER::Message.new str
        },
        
        t.pair( value: (t.hash_ | t.array) ), ->( hash_pair ) {
          name, params = hash_pair.first
          
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
  
  def meta *keys, type: t.any, default: nil
    return @meta if keys.empty?
    
    keys.each do |key|
      return type.check!( @meta[key] ) unless @meta[key].nil?
    end
    
    type.check! default
  end
  
  
  def meta? *keys
    keys.any? { |key| @meta.key? key }
  end
  
  
  def value_data
    if value.respond_to? :to_data
      value.to_data
    else
      value
    end
  end
  
  
  # Is the option is required in the CLI?
  # 
  # @return [Boolean]
  # 
  def required?
    meta :required, :require, type: t.bool, default: false
  end
  
  
  # Should we save the option value in `./.qb-options.yml`?
  # 
  # @return [Boolean]
  # 
  def save?
    meta :save, type: t.bool, default: true
  end
  
  
  # Description of the option.
  # 
  # @return [String]
  # 
  def description
    meta(
      :description,
      default: "Set the #{ @var_name } role variable"
    ).to_s
  end
  
  
  def boolean?
    type == t.bool
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
    meta? *EXAMPLES_KEYS
  end
  
  # get an array of examples for the option. returns `[]` if no examples
  # are defined.
  # 
  # @return [Array<String>]
  # 
  def examples
    Array meta( *EXAMPLES_KEYS, type: (t.nil | t.str | t.array( t.str )) )
  end
  
  
  # Does the option accept `false` as value?
  # 
  # If it does, and is not a boolean option, we also accept a `--no-<name>`
  # option format to set the value to `false`.
  # 
  # This is useful to explicitly tell QB "no, I don't want this", since we
  # treat `nil`/`null` as the same as absent, which will cause a
  # default value to be used (if available).
  # 
  # This feature does not apply to {#boolean?} options themselves, only options
  # that accept other values (though this method will of course return `true`
  # for {#boolean?} options, since they do accept `false`).
  # 
  # @return [Boolean]
  # 
  def accept_false?
    return true if meta[:accept_false]
    
    return false if type.is_a?( Class ) && type < NRSER::Props
    
    type.test?( false )
  end
  
  
end # class Option


# /Namespace
# ============================================================================

end # class Options
end # module QB
