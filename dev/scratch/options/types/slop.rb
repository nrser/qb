#!/usr/bin/env ruby

require 'bundler/setup'

require 'pp'
require 'slop'
require 'yaml'

opt_defs = YAML.load File.read(File.join(File.dirname(__FILE__), 'opts.yml'))

pp opt_defs

# ARGV = ARGV + ['--array', 'T,F,T', '--no-bool', 'F']

def make_option type
  Slop.string_to_option_class(config[:type_config]).new([], '')
end

class Slop::ArrayOfOption < Slop::ArrayOption
  # def initialize flags, desc, **config, &block
  #   super flags, desc, **config, &block
  #   @item_option = 
  # end
  
  def call value
    super(value).map {|string|
      make_option(config[:type_config]).call string
    }
  end
end

class Slop::ValueOption < Slop::Option
  def initialize flags, desc, **config, &block
    super flags, desc, **config, &block
    @value = config.fetch :type_config
  end
  
  def call value
    unless value == @value
      raise "bad value: #{ value.inspect }, should be #{ @value }"
    end
    
    value
  end
end

class Slop::OneOfOption < Slop::Option
  def initialize flags, desc, **config, &block
    super flags, desc, **config, &block
    @types = config.fetch(:type_config).map {|spec|
      case spec
      when Hash
        make_option(spec['type'])
      else
        make_option('value', type_config: spec)
      end
    }
  end
  
  def call value
    
  end
end

opts = Slop.parse(ARGV) do |o|
  # o.string '-h', '--host', 'a hostname'
  # o.integer '--port', 'custom port', default: 80
  # o.bool '-v', '--verbose', 'enable verbose mode'
  # o.bool '-q', '--quiet', 'suppress output (quiet mode)'
  # o.bool '-c', '--check-ssl-certificate', 'check SSL certificate for host'
  # o.on '--version', 'print the version' do
  #   puts Slop::VERSION
  #   exit
  # end
  
  # o.array_of '--array', 'an array of integers', item_type: 'integer'
  
  opt_defs.each do |opt_def|
    config = case opt_def['type']
    when String
      {type: opt_def['type']}
    when Hash
      {
        type: opt_def['type'].keys[0],
        type_config: opt_def['type'].values[0],
      }
    else
      raise "HERE"
    end
    
    pp config
    
    o.on  "--#{ opt_def['name'] }",
          opt_def['description'],
          **config
  end
  
  o.on '-h', 'help' do
    puts o
    exit
  end
end

pp opts.to_hash
