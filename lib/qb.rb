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