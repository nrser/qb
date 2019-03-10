# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================


# Namespace
# =======================================================================

module  QB
module  Ansible
module  Cmd
class   Playbook < Cmds


# Definitions
# =======================================================================

# Support for providing CLI options to the underlying `ansible-playbook`
# command that is run by QB to execute playbooks.
# 
module Options
  
  # destructively removes options from `@argv` and populates ansible, role,
  # and qb option hashes.
  def parse!
    parse_ansible!
    
    @role_options = {}
    
    if @role.meta['default_user']
      @qb['user'] = @role.meta['default_user']
    end
    
    opt_parser = OptionParser.new do |opts|
      opts.accept(QB::Package::Version) do |string|
        QB::Package::Version.from( string ).to_h
      end
      
      opts.banner = @role.banner
      
      opts.separator "Common options:"
      
      opts.on(
        '-H',
        '--HOSTS=HOSTS',
        Array,
        "set playbook host",
        "DEFAULT: localhost",
        SPACER
      ) do |value|
        @qb['hosts'] = value
      end
      
      opts.on(
        '-I',
        '--INVENTORY=FILEPATH',
        String,
        "set inventory file",
        SPACER
      ) do |value|
        @qb['inventory'] = value
      end
      
      opts.on(
        '-U',
        '--USER=USER',
        String,
        "ansible become user for the playbook",
        SPACER
      ) do |value|
        @qb['user'] = value
      end
      
      opts.on(
        '-T',
        '--TAGS=TAGS',
        Array,
        "playbook tags",
        SPACER
      ) do |value|
        @qb['tags'] = value
      end
      
      opts.on(
        '-V[LEVEL]',
        "run playbook in verbose mode. use like -VVV or -V3.",
        SPACER
      ) do |value|
        # QB.debug "verbose", value: value
        
        @qb['verbose'] = if value.nil?
          1
        else
          case value
          when '0'
            false
          when /^[1-4]$/
            value.to_i
          when /^[V]{1,3}$/i
            value.length + 1
          else
            raise "bad verbose value: #{ value.inspect }"
          end
        end
      end
      
      opts.on(
        '--NO-FACTS',
        "don't gather facts",
        SPACER
      ) do |value|
        @qb['facts'] = false
      end
      
      opts.on(
        '--PRINT=FLAGS',
        Array,
        "set what to print before running: options, env, cmd, playbook",
        SPACER
      ) do |value|
        @qb['print'] = value
      end
      
      opts.on(
        '--NO-RUN',
        "don't run the playbook (useful to just print stuff)",
        SPACER
      ) do |value|
        @qb['run'] = false
      end
      
      opts.separator "Role options:"
      
      self.class.add opts, @role_options, @role
      
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        
        @role.puts_examples
        
        exit
      end
    end
    
    opt_parser.parse! @argv
  end # parse!
  
end # module Options


# /Namespace
# =======================================================================

end # class  Playbook
end # module Cmd
end # module Ansible
end # module QB
