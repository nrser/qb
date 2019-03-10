# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Deps
# -----------------------------------------------------------------------

# Need {ActiveSupport::Concern} duh
require 'active_support/concern'


# Project / Package
# -----------------------------------------------------------------------

require 'qb/util'


# Refinements
# =======================================================================

require 'nrser/refinements/types'
using NRSER::Types

require 'nrser/refinements/sugar'
using NRSER::Sugar


# Namespace
# ========================================================================

module  QB
class   Options
class   Option


# Definitions
# =======================================================================

# This concern is just the stuff that interfaces the rest of 
# {QB::Options::Option} with the built-in {OptionParser}, broken out because
# {QB::Options::Option} was starting to get a little chubby.
# 
module  OptionParserConcern
  
  extend ActiveSupport::Concern
  extend ::MethodDecorators
  
  include NRSER::Log::Mixin
  
  class TypeAcceptable
    def self.name
      if self == TypeAcceptable
        "TypeAcceptable"
      else
        "TypeAcceptable<#{ type }>"
      end
    end
    
    singleton_class.send :alias_method, :to_s, :name
    singleton_class.send :alias_method, :inspect, :name
    
    def self.type
      @type
    end
    
    def self.parse string
      type.from_s string
    end
  end
  
  
  def option_parser_spacer
    ' '
  end
  
  
  def option_parser_type_acceptable
    acceptable = Class.new TypeAcceptable
    acceptable.instance_variable_set :@type, self.type
    acceptable
  end
  
  
  def option_parser_value_name
    meta_name.upcase
  end
  
  
  +QB::Util::Decorators::EnumFor
  def option_parser_format_multiline string, &block
    lines = string.lines.to_a
    
    lines.map do |line|
      yield case line
      when "\n"
        # Need a space for {OptionParser} to respect it
        option_parser_spacer + line
      when /\A\s*\-\ /
        line.sub '-', '*'
      else
        line
      end
    end
    
    yield option_parser_spacer if lines.length > 1
  end
  
  
  +QB::Util::Decorators::EnumFor
  def option_parser_description &block
    option_parser_format_multiline description, &block
  end
  
  
  +QB::Util::Decorators::EnumFor
  def option_parser_bool_args included:, &block
    # Don't use short names when included (for now)
    if !included && meta[:short]
      yield "-#{ meta[:short] }"
    end
    
    yield "--[no-]#{ cli_name }"
  end
  
  
  +QB::Util::Decorators::EnumFor
  def option_parser_non_bool_args included:, &block
    # don't use short names when included (for now)
    if !included && meta[:short]
      yield "-#{ meta[:short] } #{ option_parser_value_name }"
    end
    
    # We allow options to also accept
    if accept_false?
      yield "--[no-]#{ cli_name }=#{ option_parser_value_name }"
    else
      yield "--#{ cli_name }=#{ option_parser_value_name }"
    end
    
    yield option_parser_type_acceptable
  end
  
  
  +QB::Util::Decorators::EnumFor
  def option_parser_default &block
    ans_src_default = role.defaults[var_name]
    
    # If we don't have shit in the role default Ansible source file, nothing
    # to do here
    return if ans_src_default.nil?
    
    if boolean?
      yield "DEFAULT: --#{ ans_src_default ? '' : 'no-' }#{ cli_name }"
    else
      # This is just the Ansible "source code", which is shitty and ugly
      # for anything that's not a literal, but it at least gives you something
      # to see
      option_parser_format_multiline "DEFAULT: #{ ans_src_default }", &block
    end
  end
  
  
  +QB::Util::Decorators::EnumFor
  def option_parser_examples &block
    return unless has_examples?
    
    yield 'Examples:'
    
    examples.each_with_index do |example, index|
      lines = example.lines.to_a
      
      yield ((index + 1).to_s + '.').ljust(4) + lines.first.chomp
      
      lines[1..-1].each do |line|
        yield " ".ljust(4) + line.chomp
      end
    end
  end
  
  
  +QB::Util::Decorators::EnumFor
  def option_parser_type &block
    option_parser_format_multiline "TYPE: #{ type }", &block
  end
  
  
  +QB::Util::Decorators::EnumFor
  def option_parser_args included:, &block
    if boolean?
      option_parser_bool_args included: included, &block
    else
      option_parser_non_bool_args included: included, &block
    end
    
    option_parser_description &block
    
    yield "REQUIRED." if required?
    
    option_parser_type &block
    
    option_parser_default &block
    
    option_parser_examples &block
    
    yield option_parser_spacer
    
  end
  
  
  def option_parser_add option_parser, included:
    args = option_parser_args( included: included ).to_a
    
    args.find do |arg|
      if arg.is_a?( Class )
        option_parser.accept( arg ) do |value|
          arg.parse value
        end
        
        true
      end
    end
    
    logger.trace "Adding option to {OptionParser}",
      option_meta_name: meta_name,
      args: args
    
    option_parser.on( *args ) do |value|
      logger.debug "Setting option value",
        option_meta_name: meta_name,
        value: value
      
      self.value = value
    end
  end
  
end # module OptionParserConcern


# /Namespace
# ========================================================================

end # class   Option
end # class   Options
end # module  QB
