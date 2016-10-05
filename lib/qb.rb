require 'nrser/extras'

require "qb/version"

module QB
  ROOT = (Pathname.new(__FILE__).dirname + '..').expand_path
  ROLES_DIR = ROOT + 'roles'
  
  class Error < StandardError
  end
  
  # TODO this should be in an instance that is run instead of module global
  # hack for now
  @@debug = false
  
  def self.debug= bool
    @@debug = !!bool
  end
  
  def self.debug *args
    return unless @@debug && args.length > 0
    
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
    $stderr.puts YAML.dump(dumpObj)
  end
  
  def self.get_default_dir role, cwd, options
    debug "get_default_dir",  role: role,
                              meta: role.meta,
                              cwd: cwd,
                              options: options
    
    key = 'default_dir'
    case role.meta[key]
    when nil, false
      # there is no get_dir info in meta/qb.yml, can't get the dir
      raise "unable to infer default directory: no '#{ key }' key in meta/qb.yml"
      
    when 'git_root'
      debug "returning the git root relative to cwd"
      NRSER.git_root cwd
    
    when 'cwd'
      debug "returing current working directory"
      cwd
      
    when Hash
      debug "qb meta option is a Hash"
      
      if role.meta[key].key? 'exe'
        exe_path = role.meta[key]['exe']
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
      else
        raise "not sure to process '#{ key }' in metea/qb.yml"
      end
    end
  end
end

# needs QB::ROLES_DIR
require 'qb/role'
require 'qb/options'