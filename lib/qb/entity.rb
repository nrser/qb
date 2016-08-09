module QB
  class Field
    NO_DEFAULT = Object.new
    
    attr_reader :entity_class, :name, :type, :default
    
    def initialize entity_class, name, options
      Types.check entity_class, Types.where {|value| value < Entity}
      Types.check options, Hash
      
      @entity_class = entity_class
      
      @name = Types.check name, Symbol
      
      @type = if options.key? :type
        Types.make(options[:type])
      else
        Types.any
      end
      
      @default = if options.key? :default
        options[:default]
      else
        NO_DEFAULT
      end
    end
    
    def has_default?
      @default != NO_DEFAULT
    end
  end # Field
  
  class Entity
    def self.field name, options = {}
      @@fields ||= {}
      
      if @@fields.key? name
        raise FieldDefError.new NRSER.squish <<-END
          "field '#{ name }' already defined"
        END
      end
      
      @@fields[name] = Field.new self, name, options
      
      attr_accessor name
    end # fields
    
    def initialize values = {}
      @@fields.values.each {|field|
        # get the value
        value = if values[field.name].nil?
          # a value was not provided or `nil` was provided, which we don't
          # differntiate between (if `nil` doesn't mean nothing that what
          # does it mean?)
          # 
          # if there's a default, we want to use that
          if field.has_default?
            field.default
          
          else
            # no just return nil
            nil
            
          end # if has default / else
          
        else
          # there's a value there, so use that
          values[field.name]
          
        end # if value is nil / else
        
        # check the value (throws if bad)
        begin
          field.type.check value
        rescue TypeError => e
          raise BadValueError.new NRSER.squish <<-END
            value #{ value.inspect } provided for field '#{ field.name }' for
            Entity #{ field.entity_class } failed to pass check
            #{ field.type.inspect }.
          END
        end
        
        # set it as an instance variable
        instance_variable_set "@#{ field.name }", value
      } # each field
    end # initialize
  end # Entity
end # QB