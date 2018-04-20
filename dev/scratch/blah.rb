require 'method_decorators'
require 'nrser'

NRSER::Log.setup_for_CLI! dest: $stderr

class EnumFor < MethodDecorators::Decorator
  include NRSER::Log::Mixin
  
  def call orig, this, *args, &block
    logger.info "calling",
      orig: [orig, orig.class],
      this: [this, this.class],
      args: args,
      block: block
    
    if block
      orig.call *args, &block
    else
      this.enum_for orig.name
    end
  end
end

class A
  extend MethodDecorators
  
  def self.wrap_enum_for name
    target = instance_method name
    
    define_method name do |*args, &block|
      if block
        puts "calling target"
        target.bind( self ).call *args, &block
      else
        puts "building enum for #{ name }"
        enum_for name
      end
    end
  end
  
  +EnumFor
  def more_stuff
    yield :a
    yield :b
  end
  
  # wrap_enum_for :more_stuff
  
  +EnumFor
  def even_more_crap x, y
    yield 'more crap...'
    yield x
    yield y
  end
  
  # wrap_enum_for :even_more_crap
  
+EnumFor
  def stuff &block
    puts "calling stuff..."
    
    yield 1
    yield 2
    more_stuff &block
    even_more_crap :x, :y, &block
    yield 11
  end
  
  # wrap_enum_for :stuff
end

require 'pp'

def f *args
  pp args
end

f *A.new.stuff
