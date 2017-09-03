module QB; end
module QB::CLI; end

class QB::CLI::Run < QB::CLI::Cmd
  
end # class Run


#!/usr/bin/env ruby

require 'pathname'
require 'pp'
require 'yaml'
require 'json'
require 'fileutils'

require 'cmds'

require 'qb'

# constants
# =========



# globals
# =======



def main args
  QB.check_ansible_version
  
  role_arg = args.shift
  QB.debug "role arg" => role_arg
  
  begin
    role = QB::Role.require role_arg
  rescue QB::Role::NoMatchesError => e
    puts "ERROR - #{ e.message }\n\n"
    # exits with status code 1
    help
  rescue QB::Role::MultipleMatchesError => e
    puts "ERROR - #{ e.message }\n\n"
    exit 1
  end
  
  QB.check_qb_version role
  
  options = QB::Options.new role, args
  
  QB.debug "role options set on cli", options.role_options.select {|k, o|
    !o.value.nil?
  }
  
  QB.debug "qb options", options.qb
  
  cwd = Dir.getwd
  
  dir = nil
  
  unless role.meta['default_dir'] == false
    # get the target dir
    dir = case args.length
    when 0
      # in this case, a dir has not been provided
      # 
      # in some cases (like projects) the dir can be figured out in other ways:
      # 
      role.default_dir cwd, options.role_options
      
    when 1
      # there is a single positional arg, which is used as dir
      args[0]
      
    else
      # there are multiple positional args, which is not allowed
      raise "can't supply more than one argument: #{ args.inspect }"
      
    end
    
    QB.debug "input_dir", dir
    
    # normalize to expanded path (has no trailing slash)
    dir = File.expand_path dir
    
    QB.debug "normalized_dir", dir
    
    # create the dir if it doesn't exist (so don't have to cover this in
    # every role)
    if role.mkdir
      FileUtils.mkdir_p dir unless File.exists? dir
    end
  
    saved_options_path = Pathname.new(dir) + '.qb-options.yml'
    
    saved_options = if saved_options_path.exist?
      # convert old _ separated names to - separated
      YAML.load(saved_options_path.read).map {|role_options_key, role_options|
        [
          role_options_key,
          role_options.map {|name, value|
            [QB::Options.cli_ize_name(name), value]
          }.to_h
        ]
      }.to_h.tap {|saved_options|
        QB.debug "found saved options", saved_options
      }
    else
      QB.debug "no saved options"
      {}
    end
    
    if saved_options.key? role.options_key
      role_saved_options = saved_options[role.options_key]
      
      QB.debug "found saved options for role", role_saved_options
      
      role_saved_options.each do |option_cli_name, value|
        option = options.role_options[option_cli_name]
        
        if option.value.nil?
          QB.debug "setting from saved options", option: option, value: value
          
          option.value = value
        end
      end
    end
  end # unless default_dir == false
  
  # check that required options are present
  missing = options.role_options.values.select {|option|
    option.required? && option.value.nil?
  }
  
  unless missing.empty?
    puts "ERROR: options #{ missing.map {|o| o.cli_name } } are required."
    exit 1
  end
  
  set_options = options.role_options.select {|k, o| !o.value.nil?}
  
  QB.debug "set options", set_options
  
  playbook_role = {'role' => role.name}
  
  playbook_vars = {
    'qb_dir' => dir,
    # depreciated due to mass potential for conflict
    'dir' => dir,
    'qb_cwd' => cwd,
    'qb_user_roles_dir' => QB::USER_ROLES_DIR.to_s,
  }
  
  set_options.values.each do |option|
    playbook_role[option.var_name] = option.value
  end
  
  play =
  {
    'hosts' => options.qb['hosts'],
    'vars' => playbook_vars,
    # 'gather_subset' => ['!all'],
    'gather_facts' => options.qb['facts'],
    'pre_tasks' => [
      {
        'qb_facts' => {
          'qb_dir' => dir,
        }
      },
    ],
    'roles' => [
      'nrser.blockinfile',
      playbook_role
    ],
  }
  
  if options.qb['user']
    play['become'] = true
    play['become_user'] = options.qb['user']
  end
  
  playbook = [play]
  
  QB.debug "playbook", playbook
  
  playbook_path = Pathname.new(Dir.getwd) + '.qb-playbook.yml'
  QB.debug playbook_path: playbook_path.to_s
  
  env = {
    ANSIBLE_ROLES_PATH: [
      # stick the role path in front to make sure we get **that** role
      role.path.expand_path.dirname,
      
      # then include the full role search path
      
      # NOTE  this includes role paths pulled from a call-site local
      #       ansible.cfg
      QB::Role.search_path,
    ].
      flatten. # since QB::Role.search_path is an Array
      select(&:directory?).
      map(&:realpath). # so uniq works
      uniq, # drop dups (seems to keep first instance so preserves priority)
    
    ANSIBLE_LIBRARY: [
      QB::ROOT.join('library'),
    ],
    
    ANSIBLE_FILTER_PLUGINS: [
      QB::ROOT.join('plugins', 'filter_plugins'),
    ],
    
    ANSIBLE_LOOKUP_PLUGINS: [
      QB::ROOT.join('plugins', 'lookup_plugins'),
    ],
  }
  
  cmd_options = options.ansible.clone
  
  if options.qb['inventory']
    cmd_options['inventory-file'] = options.qb['inventory']
    
  elsif play['hosts'] != ['localhost']
    cmd_options['inventory-file'] = play['hosts']
    
  end
    
  if options.qb['tags']
    cmd_options['tags'] = options.qb['tags']
  end
  
  cmd_template = <<-END    
    ansible-playbook
    
    <%= cmd_options %>
    
    <% if verbose %>
      -<%= 'v' * verbose %>
    <% end %>
    
    <%= playbook_path %>
  END
  
  cmd_options = {
    env: env.map {|k, v| [k, v.is_a?(Array) ? v.join(':') : v]}.to_h,
    
    kwds: {
      cmd_options: cmd_options,
      
      verbose: options.qb['verbose'],
      
      playbook_path: playbook_path.to_s,
    },
    
    format: :pretty,
  }
  
  # If ./ansible/ansible.cfg exists chdir into there for the run.
  # 
  # We already look for that dir and add the role paths to the role path 
  # specified to `ansible-playbook`, but though there might be a way to make 
  # `ansible-playbook` perform as desired while retaining the current directory
  # (which would be preferable - I don't like switching directories on people)
  # for the moment it seems like the easiest way to get it to properly use
  # things like vars and relative paths in `./ansible/ansible.cfg` is to 
  # change directories into `./ansible`, so that's what we're doing here:
  if File.exists? './ansible/ansible.cfg'
    cmd_options[:chdir] = './ansible'
  end
  
  cmd = Cmds.new cmd_template, cmd_options
  
  # print
  # =====
  # 
  # print useful stuff for debugging / running outside of qb
  # 
  
  if options.qb['print'].include? 'options'
    puts "SET OPTIONS:\n\n#{ YAML.dump set_options }\n\n"
  end
  
  if options.qb['print'].include? 'env'
    dump = YAML.dump env.map {|k, v| [k.to_s, v.map {|i| i.to_s}]}.to_h
    puts "ENV:\n\n#{ dump }\n\n"
  end
  
  if options.qb['print'].include? 'cmd'
    puts "COMMAND:\n\n#{ cmd.prepare }\n\n"
  end
  
  if options.qb['print'].include? 'playbook'
    puts "PLAYBOOK:\n\n#{ YAML.dump playbook }\n\n"
  end
  
  # stop here if we're not supposed to run
  exit 0 if !options.qb['run']
  
  # run
  # ===
  # 
  # stuff below here does stuff
  # 
  
  playbook_path.open('w') do |f|
    f.write YAML.dump(playbook)
  end
  
  # save the options back
  if (
    dir &&
    # we set some options that we can save
    set_options.values.select {|o| o.save? }.length > 0 &&
    # the role says to save options
    role.save_options
  )
    saved_options[role.options_key] = set_options.select{|key, option|
      option.save?
    }.map {|key, option|
      [key, option.value]
    }.to_h
    
    unless saved_options_path.dirname.exist?
      FileUtils.mkdir_p saved_options_path.dirname
    end
    
    saved_options_path.open('w') do |f|
      f.write YAML.dump(saved_options)
    end
  end
  
  with_clean_env do
    # boot up stdio out services so that ansible modules can stream to our
    # stdout and stderr to print stuff (including debug lines) in real-time
    stdio_out_services = {'out' => $stdout, 'err' => $stderr}.
      map {|name, dest|
        QB::Util::STDIO::OutService.new(name, dest).tap { |s| s.open! }
      }
    
    # and an in service so that modules can prompt for user input
    user_in_service = QB::Util::STDIO::InService.new('in', $stdin).
      tap { |s| s.open! }
    
    status = cmd.stream
    
    # close the stdio services
    stdio_out_services.each {|s| s.close! }
    user_in_service.close!
    
    if status != 0
      puts "ERROR ansible-playbook failed."
    end
    
    exit status
  end
end

main(ARGV) # if __FILE__ == $0 # doesn't work with gem stub or something?
