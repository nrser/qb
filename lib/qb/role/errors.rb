module QB
  class Role
    # raised by `.require` when no roles match input
    class NoMatchesError < QB::UserInputError
      attr_accessor :input
      
      def initialize input
        @input = input
        
        super "no roles match input #{ @input.inspect }"
      end
    end
    
    # raised by `.require` when multiple roles match
    class MultipleMatchesError < QB::UserInputError
      attr_accessor :input, :matches
      
      def initialize input, matches
        @input = input
        @matches = matches
        
        super <<-END
multiple roles match input #{ @input.inspect }:\

#{
  @matches.map { |role|
    "-   #{ role.to_s } (#{ role.path.to_s })"
  }.join("\n")
}

END
      end
    end
    
    # raised when there's bad metadata 
    class MetadataError < QB::StateError
    end
  end # Role
end # QB