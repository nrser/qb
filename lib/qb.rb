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
    return unless @@debug
    
    msg, values = case args.length
    when 0
      raise ArgumentError, "debug needs at least one argument"
    when 1
      if args[0].is_a? Hash
        ['', args[0]]
      else
        [args[0], {}]
      end
    when 2
      [args[0], args[1]]
    else
      raise ArgumentError, "debug needs at least one argument"
    end
    
    $stderr.puts("DEBUG " + format(msg, values))
  end
  
  def self.get_default_dir role, cwd, options
    debug "get_default_dir",  role: role,
                              meta: qb.meta,
                              cwd: cwd,
                              options: options
    
    key = 'default_dir'
    case qb.meta[key]
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
      
      if qb.meta[key].key? 'exe'
        exe_path = qb.meta[key]['exe']
        exe_input_data = options
        
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