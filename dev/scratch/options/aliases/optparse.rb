require 'optparse'
require 'yaml'

opts = {}

parser = OptionParser.new do |parser|
  parser.banner = "hey there"
  
  parser.on(
    '-X VALUE',
    'x',
  ) do |value|
    opts['x'] = value
  end
  
  parser.on(
    '-I INVENTORY', '-H INVENTORY',
    '--INVENTORY=INVENTORY', '--HOSTS=INVENTORY',
    Array,
    "inventory",
  ) do |value|
    opts['hosts'] = value
  end
  
  parser.on_tail('-h') do
    puts parser
  end
end

parser.parse! ARGV

puts YAML.dump(opts)
