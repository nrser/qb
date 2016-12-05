module QB
  module Util
    # split a string into 'words' for word-based matching
    def self.words string
      string.split(/[\W_-]+/).reject {|w| w.empty?}
    end # .words
    
    # see if words from an input match words 
    def self.words_start_with? full_string, input
      # QB.debug "does #{ input } match #{ full_string }?"
      
      input_words = words input
      full_string_words = words full_string
      
      full_string_words.each_with_index {|word, start_index|
        # compute the end index in full_string_words
        end_index = start_index + input_words.length - 1
        
        # short-circuit if can't match (more input words than full words left)
        if end_index >= full_string_words.length
          return false
        end
        
        # create the slice to test against
        slice = full_string_words[start_index..end_index]
        
        # see if every word in the slice starts with the corresponding word
        # in the input
        if slice.zip(input_words).all? {|full_word, input_word|
          full_word.start_with? input_word
        }
          # got a match!
          return true
        end
      }
      
      # no match
      false
    end # .match_words?
  end # Util
end # QB