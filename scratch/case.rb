class Object
  def on_length procs
    length_map = procs.map {|proc|
      [proc.arity, proc]
    }.to_h
    
    length_map[length].(*self)
  end
end

def f args
  puts "args: #{ args.inspect }"
  args.on_length([
    -> {
      puts "none"
    },
    ->(x) {
      puts "single: #{ x }"
    },
    ->(x, y) {
      puts "double: #{ x }, #{ y }"
    },
  ])
  puts
end

f = (args) ->
  (x) ->
    (x:Hash) ->
      ['', x]
    (x) ->
      [x, {}]
      
  (x, y) -> [x, y]

f []
f [:x]
f [:x, :y]