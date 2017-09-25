require 'nrser/extras'

require_relative './qb/errors'
require_relative './qb/version'
require_relative './qb/util'
require_relative './qb/path'

module QB
  ROOT = (Pathname.new(__FILE__).dirname + '..').expand_path
  GEM_ROLES_DIR = ROOT + 'roles'
  USER_ROLES_DIR = Pathname.new(ENV['HOME']).join '.ansible', 'roles'
  
  
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
    
end

# needs QB::*_ROLES_DIR
require 'qb/role'
require 'qb/options'
require_relative './qb/repo'
require_relative './qb/cli'

require_relative './qb/ansible'
# Depreciated namespace:
require_relative './qb/ansible_module'

