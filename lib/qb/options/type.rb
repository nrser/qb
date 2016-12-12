
class QB::Options::Type
  NAMES = {
    String => ['str', 'string'],
    Array => ['array', 'list'],
    Integer => ['integer', 'int'],
    Numeric => ['number', 'num'],
    Float => ['float', 'decimal', 'dec'],
    # stupid fucking true and false class :/
    [TrueClass, FalseClass] => ['boolean', 'bool'],
  }
  
  def initialize definition
    @definition = definition
    
  end
  
  def parse string
    
  end
  
end