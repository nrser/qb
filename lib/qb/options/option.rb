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

# Base class for all options, which can be fed into an {OptionParser} to 
# extract them from CLI args.
# 
class Option
  
  # Constants
  # ========================================================================
  
  EXAMPLES_KEYS = ['examples', 'example'].freeze
  
  
  # Mixins
  # ============================================================================
  
  include NRSER::Log::Mixin
  
  include OptionParserConcern
  
  
  # Attributes
  # ========================================================================
  
  # The name that this option will be available in the cli as
  # 
  # @return [String]
  # 
  attr_reader :cli_name
  
  
  # The value of the option, or `nil` if we never assign one
  # 
  # @return [Object]
  # 
  attr_accessor :value
  
  
  # What type of values the option accepts.
  # 
  # @return [NRSER::Types::Type]
  #     
  attr_reader :type
  
  
  # Construction
  # ======================================================================
  
  def initialize cli_name:, type:, value: nil
    @cli_name = t.NonEmptyString.check! cli_name
    @value = value
    @type = t.Type.check! type
  end
  

  # Instance Methods
  # ========================================================================
  
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

end # class  Options
end # module QB
