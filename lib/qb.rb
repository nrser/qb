require 'nrser/extras'

require "qb/version"
require "qb/util"
require 'qb/util/stdio'
require "qb/ansible_module"

module QB
  ROOT = (Pathname.new(__FILE__).dirname + '..').expand_path
  GEM_ROLES_DIR = ROOT + 'roles'
  USER_ROLES_DIR = Pathname.new(ENV['HOME']).join '.ansible', 'roles'
  MIN_ANSIBLE_VERSION = Gem::Version.new '2.1.2'
  
  class Error < StandardError
  end
  
  def self.debug *args
    return unless ENV['QB_DEBUG'] && args.length > 0
    
    header = 'DEBUG'
    
    if args[0].is_a? String
      header += " " + args.shift
    end
    
    dumpObj = case args.length
    when 0
      header
    when 1
      {header => args[0]}
    else
      {header => args}
    end
    
    # $stderr.puts("DEBUG " + format(msg, values))
    $stderr.puts dumpObj.pretty_inspect
  end
  
  def self.get_default_dir role, cwd, options
    debug "get_default_dir",  role: role,
                              meta: role.meta,
                              cwd: cwd,
                              options: options
    
    key = 'default_dir'
    value = role.meta[key]
    case value
    when nil
      # there is no get_dir info in meta/qb.yml, can't get the dir
      raise "unable to infer default directory: no '#{ key }' key in meta/qb.yml"
    
    when false
      # this method should not get called when the value is false (an entire
      # section is skipped in exe/qb when `default_dir = false`)
      raise "role does not use default directory (meta/qb.yml:default_dir = false)"
    
    when 'git_root'
      debug "returning the git root relative to cwd"
      NRSER.git_root cwd
    
    when 'cwd'
      debug "returning current working directory"
      cwd
      
    when Hash
      debug "qb meta option is a Hash"
      
      unless value.length == 1
        raise "#{ role.meta_path.to_s }:default_dir invalid: #{ value.inspect }"
      end
      
      hash_key, hash_value = value.first
      
      case hash_key
      when 'exe'
        exe_path = hash_value
        
        # supply the options to the exe so it can make work off those values
        # if it wants.
        exe_input_data = Hash[
          options.map {|option|
            [option.cli_option_name, option.value]
          }
        ]
        
        unless exe_path.start_with?('~') || exe_path.start_with?('/')
          exe_path = File.join(role.path, exe_path)
          debug 'exe path is relative, basing off role dir', exe_path: exe_path
        end
        
        debug "found 'exe' key, calling", exe_path: exe_path,
                                          exe_input_data: exe_input_data
        
        Cmds.chomp! exe_path do
          JSON.dump exe_input_data
        end
        
      when 'find_up'
        filename = hash_value
        
        unless filename.is_a? String
          raise "find_up filename must be string, found #{ filename.inspect }"
        end
        
        debug "found 'find_up', looking for file named #{ filename }"
        
        Util.find_up filename
        
      else
        raise "bad key: #{ hash_key } in #{ role.meta_path.to_s }:default_dir"
        
      end
    end
  end # get_default_dir
  
  def self.check_ansible_version
    out = Cmds.out! 'ansible --version'
    version_str = out[/ansible\ ([\d\.]+)/, 1]
    
    if version_str.nil?
      raise NRSER.dedent <<-END
        could not parse ansible version from `ansible --version` output:
        
        #{ out }
      END
    end
    
    version = Gem::Version.new version_str
    
    if version < QB::MIN_ANSIBLE_VERSION
      raise NRSER.squish <<-END
        qb #{ QB::VERSION } requires ansible #{ QB::MIN_ANSIBLE_VERSION },
        found version #{ version_str } at #{ `which ansible` }
      END
    end
  end
end

# needs QB::*_ROLES_DIR
require 'qb/role'
require 'qb/options'