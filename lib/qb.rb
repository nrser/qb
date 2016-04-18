require 'nrser/extras'

require "qb/version"

module QB
  ROOT = (Pathname.new(__FILE__).dirname + '..').expand_path
  ROLES_DIR = ROOT + 'roles'
  
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
  
  def self.get_default_dir qb_meta, cwd, options
    key = 'default_dir'
    case qb_meta[key]
    when nil
      # there is no get_dir info in meta/qb.yml, can't get the dir
      raise "unable to infer default directory: no '#{ key }' key in meta/qb.yml"
      
    when 'git_root'
      NRSER.git_root cwd
      
    when Hash
      if qb_meta[key].key? 'exe'
        exe_path = qb_meta[key]['exe']
        
        Cmds.chomp! exe_path do
          JSON.dump options
        end
      else
        raise "not sure to process '#{ key }' in metea/qb.yml"
      end
    end
  end
end

# needs QB::ROLES_DIR
require 'qb/role'