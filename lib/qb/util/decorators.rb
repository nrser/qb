# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Deps
# -----------------------------------------------------------------------

require 'method_decorators'


# Definitions
# =======================================================================

# Python-style decorators using the `method_decorators` gem.
# 
# @see https://rubygems.org/gems/method_decorators
# 
# @example Usage
#   class A
#     extend MethodDecorators
#     
#     +QB::Util::Decorators::EnumFor
#     def get_stuff
#       yield 1
#       yield 2
#       yield 3
#     end
#     
#   end
#   
#   A.new.get_stuff.class
#   # => Enumerator
#   
module QB; module Util; module Decorators
  
  # Wrap a method that yields, returning an {Enumerator} if no block is
  # given.
  # 
  # Implements the common "enum_for" pattern:
  #   
  #   def f
  #     return enum_for( __method__ ) unless block_given?
  #     yield 1
  #     # ...
  #   end
  # 
  class EnumFor < MethodDecorators::Decorator
    # @param [Method] target
    #   The decorated method, already bound to the receiver.
    #   
    #   The `method_decorators` gem calls this `orig`, but I thought `target`
    #   made more sense.
    # 
    # @param [*] receiver
    #   The object that will receive the call to `target`.
    #   
    #   The `method_decorators` gem calls this `this`, but I thought `receiver`
    #   made more sense.
    #   
    #   It's just `target.receiver`, but the API is how it is.
    # 
    # @param [Array] *args
    #   Any arguments the decorated method was called with.
    # 
    # @param [Proc?] &block
    #   The block the decorated method was called with (if any).
    # 
    def call target, receiver, *args, &block
      if block
        target.call *args, &block
      else
        receiver.enum_for target.name, *args
      end
    end
  end # EnumFor
  
end; end; end # module QB::Util::Decorators
