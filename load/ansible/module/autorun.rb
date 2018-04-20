
# Reinstate Bundler ENV vars if they have been moved
load ENV['QB_REBUNDLE_PATH'] if ENV['QB_REBUNDLE_PATH']

require 'active_support/core_ext/class/subclasses'
require 'qb/ansible/module'

require 'nrser'
require 'nrser/types'

def t; NRSER::Types; end

QB::Ansible::Module.setup_io!

at_exit do
  if $!
    QB::Ansible::Module.logger.fatal "Error raised pre-execution", $!
  else
    QB::Ansible::Module.subclasses.find_only { |klass|
      begin
        klass.instance_method( :main ).source_location[0] == $0
      rescue; end
    }.run!
  end
end
