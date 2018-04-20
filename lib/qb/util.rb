require_relative './util/interop'
require_relative './util/bundler'
require_relative './util/decorators'

require 'nrser'

module QB
  module Util
    
    # Split a string into 'words' for word-based matching
    # 
    # @return [Array<String>]
    #   Array of non-empty words in `string`.
    # 
    def self.words string
      string.words
    end # .words
    
    
    def self.words_slice? full_string, input, &is_match
      full_string.words.slice? input.words, &is_match
    end # .words_include?
    
    
    # see if words from an input match words
    def self.words_start_with? full_string, input
      words_slice? full_string, input do |full_string_word, input_word|
        full_string_word.start_with? input_word
      end
    end # .words_start_with?
    
    
    # @return [Pathname] absolute resolved path.
    def self.resolve *segments
      joined = Pathname.new ''
      
      ([Dir.pwd] + segments).reverse.each_with_index {|segment, index|
        joined = Pathname.new(segment).join joined
        return joined if joined.absolute?
      }
      
      # shouldn't ever happen
      raise "resolution failed: #{ segments.inspect }"
    end
    
    # do kind of the opposite of File.expand_path -- turn the home dir into ~
    # and the current dir into .
    # 
    # @param [Pathname | String]
    #   path to contract.
    # 
    # @return [Pathname]
    #   contracted path.
    # 
    def self.contract_path path
      contracted = if path.start_with? Dir.pwd
        path.sub Dir.pwd, '.'
      elsif path.start_with? ENV['HOME']
        path.sub ENV['HOME'], '~'
      else
        path
      end
      
      Pathname.new contracted
    end
    
    
    # find `filename` in `from` or closest parent directory.
    # 
    # @param [String] filename
    #   name of file to search for.
    # 
    # @param [Pathname] from (Pathname.pwd)
    #   directory to start from.
    # 
    # @param [Boolean] raise_on_not_found:
    #   When `true`, a {QB::FSStateError} will be raised if no file is found
    #   (default behavior).
    #   
    #   This is something of a legacy behavior - I think it would be better
    #   to have {find_up} return `nil` in that case and add a `find_up!`
    #   method that raises on not found. But I'm not going to do it right now.
    # 
    # @return [Pathname]
    #   Pathname of found file.
    # 
    # @return [nil]
    #   If no file is found and the `raise_on_not_found` option is `false`.
    # 
    # @raise [QB::FSStateError]
    #   If file is not found in `from` or any of it's parent directories
    #   and the `raise_on_not_found` option is `true` (default behavior).
    # 
    def self.find_up filename, from = Pathname.pwd, raise_on_not_found: true
      path = from + filename
      
      return from if path.exist?
      
      parent = from.parent
      
      if from == parent
        if raise_on_not_found
          raise "not found in current or any parent directories: #{ filename }"
        else
          return nil
        end
      end
      
      return find_up filename, parent, raise_on_not_found: raise_on_not_found
    end # .find_up
  end # Util
end # QB
