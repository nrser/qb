module QB
  module Types
    def self.check value, type
      Type.make(type).check(value)
    end
    
    class Type
      def self.make value
        if value.is_a? Type
          value
        elsif value.is_a? Class
          IsA.new value
        else
          Is.new value
        end
      end
      
      def test value
        raise NotImplementedError
      end
      
      def check value
        unless test value
          raise TypeError.new NRSER.squish <<-END
            value #{ value.inspect } failed check #{ self.inspect }
          END
        end
        
        value
      end
    end # Type
    
    def self.make value
      Type.make value
    end
    
    class Any < Type
      def test value
        true
      end
    end # Any
    
    ANY = Any.new
    
    def self.any
      ANY
    end
    
    class Maybe < Type
      attr_accessor :type
      
      def initialize value
        @type = Type.make value
      end
      
      def test value
        value.nil? || @type.test(value)
      end
    end # Maybe
    
    def self.maybe value
      Maybe.new value
    end
    
    class Is < Type
      attr_reader :value
      
      def initialize value
        @value = value
      end
      
      def test value
        @value == value
      end
    end # Is
    
    class IsA < Type
      attr_reader :klass
      
      def initialize klass
        @klass = klass
      end
      
      def test value
        value.is_a? @klass
      end
    end # IsA
    
    class Where < Type
      attr_reader :method
      
      def initialize method
        @method = method
      end
      
      def test value
        !!@method.call(value)
      end
    end # Where
    
    def self.where &block
      Where.new block
    end
    
    class OneOf < Type
      attr_reader :types
      
      def initialize *types
        @types = types.map {|type| Type.make type}
      end
        
      def test value
        @types.any? {|type| type.test value}
      end
    end # OneOf
    
    def self.one_of *types
      OneOf.new *types
    end
    
    class AllOf < Type
      attr_reader :types
      
      def initialize *types
        @types = types.map {|type| Type.make type}
      end
      
      def test value
        @types.all? {|type| type.test value}
      end
    end
    
    def self.all_of *types
      AllOf.new *types
    end
    
    BOOL = one_of(true, false)
    
    def self.bool
      BOOL
    end
    
    FIXNUM = IsA.new Fixnum
    
    def self.fixnum
      FIXNUM
    end
    
    INT = FIXNUM
    
    def self.int
      INT
    end
    
    class Bounded < Type
      ATTR_TYPE = Types.maybe INT
      
      def initialize options
        @min = ATTR_TYPE.check options[:min]
        @max = ATTR_TYPE.check options[:max]
      end
      
      def test value
        return false if @min && value < @min
        return false if @max && value > @max
        true
      end
    end # Bounded
    
    POS_INT = AllOf.new INT, Bounded.new(min: 1)
    
    def self.pos_int
      POS_INT
    end
    
    NEG_INT = AllOf.new INT, Bounded.new(max: -1)
    
    def self.neg_int
      NEG_INT
    end
    
    NON_POS_INT = AllOf.new INT, Bounded.new(max: 0)
    
    def self.non_pos_int
      NON_POS_INT
    end
    
    NON_NEG_INT = AllOf.new INT, Bounded.new(min: 0)
    
    def self.non_neg_int
      NON_NEG_INT
    end
    
    class Length < Type
      ATTR_TYPE = Types.maybe NON_NEG_INT
      
      def initialize options
        @min = ATTR_TYPE.check options[:min]
        @max = ATTR_TYPE.check options[:max]
      end
      
      def test value
        return false if @min && value.length < @min
        return false if @max && value.length > @max
        true
      end
    end
    
    class String < IsA
      attr_reader :length
      
      def initialize options = {}
        super ::String
        @length = Length.new options
      end
      
      def test value
        return false unless super value
        return false unless @length.test value
        true
      end
    end # String
    
    STRING = IsA.new(::String)
    
    def self.string options = {}
      if options.empty?
        # if there are no options can point to the constant for efficency
        STRING
      else
        # otherwise we need an instance to hold the options
        String.new options
      end
    end # string
    
    class Hash < Type
      attr_reader :keys, :values, :including, :exactly, :min, :max
      
      def initialize options = {}
        
      end
    end # Hash
     
  end # Types
end # QB