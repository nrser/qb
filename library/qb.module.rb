#!/usr/bin/env ruby
# WANT_JSON

# Reinstate Bundler ENV vars if they have been moved
load ENV['QB_REBUNDLE_PATH'] if ENV['QB_REBUNDLE_PATH']

require 'qb/ansible/module'

require 'nrser'
require 'nrser/core_ext/string'
require 'nrser/types'

def t; NRSER::Types; end

QB::Ansible::Module.setup_io!

class QB_Ansible_Module_Runner < QB::Ansible::Module
  
  
  # @!attribute [r] name
  #   Name of module to run (relative path from `//lib/qb/ansible/modules`)
  #   
  #   @return [PropRubyType]
  #   
  arg :module_name,
      type: t.non_empty_str,
      aliases: [ :name ],
      reader: { name: false }
  
  arg :module_require,
      type: (
        t.nil | # Guess and try the require path
        t.false | # Don't require anything; module class must already be loaded
        t.non_empty_str | # String to require
        t.list( t.non_empty_str ) # List of strings to require
      ),
      aliases: [ :require ],
      reader: { require: false }
  
  arg :module_args,
      type: t.map,
      aliases: [ :args ],
      reader: { args: false },
      default: ->{ {} }
  
  def main
    class_name = module_name.camelize
    class_path = module_name.underscore
    
    logger.trace "Received module argument",
      module_name: module_name,
      class_name: class_name,
      class_path: class_path,
      module_require: module_require
    
    unless class_name.start_with? '::'
      class_name = "QB::Ansible::Modules::#{ class_name }"
    end
    
    require_paths = case module_require
    when nil
      if class_path.start_with? '/'
        [ class_path[1..-1] ]
      else
        [ "qb/ansible/modules/#{ class_path }" ]
      end
    when false
      []
    when String
      [ module_require ]
    when Array
      module_require
    end
    
    if require_paths.empty?
      logger.trace "No requiring any paths"
    else
      logger.trace "Requiring paths...",
        require_paths: require_paths
      
      require_paths.each do |require_path|
        begin
          require require_path
        rescue LoadError => error
          logger.warn "Failed to require #{ require_path.inspect }", error
        end
      end
    end
    
    module_class = class_name.to_const!
    
    logger.trace "Loaded class",
      module_class: module_class.to_s
    
    instance = module_class.from_data module_args
    instance.args_source = args_source
    instance.args = args['args'] || args['module_args'] || {}
    
    instance.run!
  end
    
end # class QB_Ansible_Module_Runner


QB_Ansible_Module_Runner.run!
