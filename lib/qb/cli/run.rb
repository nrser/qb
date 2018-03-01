# Requirements
# =====================================================================

# package
require 'qb/cli/help'


# Declarations
# =======================================================================

module QB; end


# Definitions
# =======================================================================

module QB::CLI
  
  # Run a QB role.
  # 
  # @param [Array<String>] args
  #   CLI args to work with.
  # 
  # @return [Fixnum]
  #   Exit status code from `ansible-playbook` command, unless we invoked
  #   help or error'd out in another way before the run (in which case `1`
  #   is returned).
  # 
  def self.run args
    role_arg = args.shift
    QB.debug "role arg" => role_arg
    
    begin
      role = QB::Role.require role_arg
    rescue QB::Role::NoMatchesError => e
      puts "ERROR - #{ e.message }\n\n"
      # exits with status code 1
      return help
    rescue QB::Role::MultipleMatchesError => e
      puts "ERROR - #{ e.message }\n\n"
      return 1
    end
    
    role.check_requirements
    
    options = QB::Options.new role, args
    
    QB.debug "Role options set on cli",
      role: options.role_options.reject { |k, o| o.value.nil? }
    
    QB.debug "QB options", options.qb.dup
    QB.debug "Ansible options", options.ansible.dup
    
    cwd = Dir.getwd
    
    dir = nil
    
    if role.has_dir_arg?
      # get the target dir
      dir = case args.length
      when 0
        # in this case, a dir has not been provided
        # 
        # in some cases (like projects) the dir can be figured out in other ways:
        # 
        
        if options.ask?
          default = begin
            role.default_dir cwd, options.role_options
          rescue QB::UserInputError => e
            NRSER::NO_ARG
          end
          
          QB::CLI.ask name: "target directory (`qb_dir`)",
                      type: t.non_empty_str,
                      default: default
          
        else
          role.default_dir cwd, options.role_options
        end
        
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
    
    
    # Interactive Input
    # =====================================================================
    
    if options.ask?
      # Incomplete
      raise "COMING SOON!!!...?"
      QB::CLI.ask_for_options role: role, options: options
    end
    
    
    # Validation
    # =====================================================================
    # 
    # Should have already been taken care of if we used interactive input.
    # 
    
    # check that required options are present
    missing = options.role_options.values.select {|option|
      option.required? && option.value.nil?
    }
    
    unless missing.empty?
      puts "ERROR: options #{ missing.map {|o| o.cli_name } } are required."
      return 1
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
      ],
    }
    
    if role.meta['call_role']
      logger.debug "Calling role through qb/call..."
      
      play['tasks'] = [
        {
          'include_role' => {
            'name' => 'qb/call',
          },
          'vars' => {
            'role' => role.name,
            'args' => set_options.map { |option|
              [option.var_name, option.value]
            }.to_h,
          }
        }
      ]
      
      env = QB::Ansible::Env::Devel.new
      exe = [
        QB::Python.bin,
        (QB::Ansible::Env::Devel::ANSIBLE_HOME / 'bin' / 'ansible-playbook')
      ].join " "
      
    else
      play['roles'] << playbook_role
      env = QB::Ansible::Env.new
      exe = "ansible-playbook"
      
    end
    
    if options.qb['user']
      play['become'] = true
      play['become_user'] = options.qb['user']
    end
    
    playbook = [play]
    
    logger.debug "playbook", playbook
    
    # stick the role path in front to make sure we get **that** role
    env.roles_path.unshift role.path.expand_path.dirname
    
    cmd = QB::Ansible::Cmds::Playbook.new \
      env: env,
      playbook: playbook,
      role_options: options,
      chdir: (File.exists?('./ansible/ansible.cfg') ? './ansible' : nil),
      exe: exe
    
    # print
    # =====
    # 
    # print useful stuff for debugging / running outside of qb
    # 
    
    if options.qb['print'].include? 'options'
      puts "SET OPTIONS:\n\n#{ YAML.dump set_options }\n\n"
    end
    
    if options.qb['print'].include? 'env'
      puts "ENV:\n\n#{ YAML.dump cmd.env.to_h }\n\n"
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
    
    logger.debug "Command prepared, running...",
      command: cmd,
      prepared: cmd.prepared
    
    status = cmd.stream
    
    if status != 0
      $stderr.puts "ERROR ansible-playbook failed."
    end
    
    # exit status
    status
  end # .run
  
end # module QB::CLI
