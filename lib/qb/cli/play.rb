# Requirements
# =====================================================================

# package
require 'qb/ansible/cmds/playbook'


# Declarations
# =======================================================================

module QB; end


# Definitions
# =======================================================================

module QB::CLI 
  
  # Play an Ansible playbook (like `state.yml`) in the QB environment 
  # (sets up path env vars, IO streams, etc.).
  # 
  # @param [Array<String>] args
  #   CLI arguments to use.
  # 
  # @return [Fixnum]
  #   The `ansible-playbook` command exit code.
  # 
  def self.play args
    if args.empty?
      raise "Need path to playbook in first arg."
    end
    
    playbook_path = QB::Util.resolve args[0]
    
    unless playbook_path.file?
      raise "Can't find Ansible playbook at #{ path.to_s }"
    end
    
    # By default, we won't change directories to run the command.
    chdir = nil
    
    # See if there is an Ansible config in the parent directories
    ansible_cfg_path = QB::Util.find_up \
      QB::Ansible::ConfigFile::FILE_NAME,
      playbook_path.dirname,
      raise_on_not_found: false
    
    # If we did find an Ansible config, we're going to want to run in that
    # directory and add it to the role search path so that we merge it's 
    # values into our env vars (otherwise they would override the config
    # values).
    unless ansible_cfg_path.nil?
      QB::Role::PATH.unshift ansible_cfg_path.dirname
      chdir = ansible_cfg_path.dirname
    end
    
    cmd = QB::Ansible::Cmds::Playbook.new \
      playbook_path: playbook_path,
      chdir: chdir
    
    status = cmd.stream
    
    if status != 0
      $stderr.puts "ERROR ansible-playbook failed."
    end
    
    exit status
    
  end # .play
  
end # module QB::CLI
