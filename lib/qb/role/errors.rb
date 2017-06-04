module QB
  class Role
    # raised by `.require` when no roles match input
    class NoMatchesError < QB::Error
      attr_accessor :input
      
      def initialize input
        @input = input
        
        super "no roles match input #{ @input.inspect }"
      end
    end
    
    # raised by `.require` when multiple roles match
    class MultipleMatchesError < QB::Error
      attr_accessor :input, :matches
      
      def initialize input, matches
        @input = input
        @matches = matches
        
        super "mutiple roles match input #{ @input.inspect }:\n#{ @matches.join("\n") }"
      end
    end
    
    # raised when there's bad metadata 
    class MetadataError < QB::Error
    end
  end # Role
end # QB