# frozen_string_literal: true

##
# {QB::Role.matches} method, which is the (messy) bulk of figuring out what
# role to run based on user input.
# 
# Broken out from the main `//lib/qb/role.rb` file because it was starting to
# get long and unwieldy.
# 
##

# Refinements
# =======================================================================

using NRSER
using NRSER::Types


# Definitions
# =======================================================================

class QB::Role
  
  # Get an array of {QB::Role} that match an input string.
  # 
  # This is the meat of whats needed to support {QB::Role.require}.
  # 
  # How it works is... tricky. Read the comments and play around with it is
  # the bast I can offer right now.
  # 
  # @param [String] input
  #   The input string to match against role paths and names. Primarily what
  #   the user typed after `qb run` on the CLI.
  # 
  # @return [Array<QB::Role>]
  # 
  def self.matches input
    # keep this here to we don't re-gen every loop
    available = self.available
    
    # first off, see if input matches any relative paths exactly
    available.each {|role|
      return [role] if role.display_path.to_s == input
    }
    
    # create an array of "separator" variations to try *exact* matching
    # against. in order of preference:
    # 
    # 1.  exact input
    #     -   this means if you ended up with roles that actually *are*
    #         differentiated by '_/-' differences (which, IMHO, is a
    #         horrible fucking idea), you can get exactly what you ask for
    #         as a first priority
    # 2.  input with '-' changed to '_'
    #     -   prioritized because convention is to underscore-separate
    #         role names.
    # 3.  input with '_' changed to '-'
    #     -   really just for convenience's sake so you don't really have to
    #         remember what separator is used.
    #     
    separator_variations = [
      input,
      input.gsub('-', '_'),
      input.gsub('_', '-'),
    ]
    
    # {QB::Role} method names to check against, from highest to lowest
    # precedence
    method_names = [
      # 1.  The path we display to the user. This comes first because typing
      #     in exactly what they see should always work.
      :display_name,
      
      # 2.  The role's full name (with namespace) as it is likely to be used
      #     in Ansible
      :name,
      
      # 3.  The part of the role after the namespace, which is far less
      #     specific, but nice short-hand if it's unique
      :namespaceless
    ]
    
    # 1.  Exact matches (allowing `-`/`_` substitution)
    #     
    #     Highest precedence, guaranteeing that exact verbatim matches will
    #     always work (or that's the intent).
    # 
    method_names.each { |method_name|
      separator_variations.each { |variation|
        matches = available.select { |role|
          role.public_send( method_name ) == variation
        }
        return matches unless matches.empty?
      }
    }
    
    # 2.  Prefix matches
    #     
    #     Do any of {#display_path}, {#name} or {#namespaceless} or start with
    #     the input pattern?
    # 
    method_names.each { |method_name|
      separator_variations.each { |variation|
        matches = available.select { |role|
          role.public_send( method_name ).start_with? variation
        }
        return matches unless matches.empty?
      }
    }
    
    # 3.  Word slice full matches
    #     
    #     Split the {#display_name} and input first by `/` and `.` segments,
    #     then {String#downcase} each segments and split it into words (using
    #     {NRSER.words}).
    #     
    #     Then see if the input appears in the role name.
    #     
    #     We test only {#display_name} because it should always contain
    #     {#name} and {#namesaceless}, so it's pointless to test the other
    #     two after it).
    # 
    
    word_parse = ->( string ) {
      string.split( /[\/\.]/ ).map { |seg| seg.downcase.words }
    }
    
    input_parse = word_parse.call input
    
    exact_word_slice_matches = available.select { |role|
      word_parse.call( role.display_name ).slice? input_parse
    }
    
    return exact_word_slice_matches unless exact_word_slice_matches.empty?
    
    # 4.  Word slice prefix matches
    #     
    #     Same thing as (3), but do a prefix match instead of the entire
    #     words.
    # 
    name_word_matches = available.select { |role|
      word_parse.call( role.display_name ).
        slice?( input_parse ) { |role_words, input_words|
          # Use a custom match block to implement prefix matching
          # 
          # We want to match if each input word is the start of the
          # corresponding role name word
          # 
          if role_words.length >= input_words.length
            input_words.each_with_index.all? { |input_word, index|
              role_words[index].start_with? input_word
            }
          else
            false
          end
        }
      QB::Util.words_start_with? role.display_path.to_s, input
    }
    return name_word_matches unless name_word_matches.empty?
    
    # nada
    []
  end # .matches
  
end # class QB::Role
