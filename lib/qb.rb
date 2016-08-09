require 'nrser/extras'

require "qb/version"
require 'qb/errors'
require 'qb/types'
require 'qb/entity'
require 'qb/var'

module QB
  ROOT = (Pathname.new(__FILE__).dirname + '..').expand_path
  ROLES_DIR = ROOT + 'roles'
  
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
  
  def self.role_dirs
    [
      ROLES_DIR,
      Pathname.new(Dir.getwd).join('roles'),
      Pathname.new(Dir.getwd).join('dev', 'roles'),
      Pathname.new(Dir.getwd).join('dev', 'roles', 'tmp'),
    ]
  end
  
  def self.available_roles
    role_dirs.
      select {|role_dir|
        role_dir.directory?
      }.
      map {|role_dir|
        role_dir.children.select {|child| role? child }
      }.
      flatten.
      uniq.
      map {|role_dir|
        QB::Role.new role_dir
      }
  end
  
  def self.role_matches input
    available_roles.each {|role|
      # exact match to relitive path
      return [role] if role.rel_path.to_s == input
    }.each {|role|
      # exact match to full name
      return [role] if role.name == input
    }.each {|role|
      # exact match without the namespace prefix ('qb.' or similar)
      return [role] if role.namespaceless == input
    }.select {|role|
      # select any that have that string in them
      role.rel_path.to_s.include? input
    }
  end
  
  def self.get_default_dir role, qb_meta, cwd, options
    debug "get_default_dir",  role: role,
                              qb_meta: qb_meta,
                              cwd: cwd,
                              options: options
    
    key = 'default_dir'
    case qb_meta[key]
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
      
      if qb_meta[key].key? 'exe'
        exe_path = qb_meta[key]['exe']
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