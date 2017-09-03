require 'nrser/extras'

require_relative './qb/debug'
require_relative './qb/errors'
require_relative './qb/version'
require_relative './qb/util'
require_relative './qb/ansible_module'

module QB
  ROOT = (Pathname.new(__FILE__).dirname + '..').expand_path
  QB_GEM_ROLES_DIR = ROOT + 'roles'
  USER_ROLES_DIR = Pathname.new(ENV['HOME']).join '.ansible', 'roles'
end

# needs QB::*_ROLES_DIR
require 'qb/role'
require 'qb/options'
require_relative './qb/repo'
require_relative './qb/action'