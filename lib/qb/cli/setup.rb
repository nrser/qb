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
  
  # Play `//dev/setup.yml`
  # 
  # @param [Array<String>] args
  #   CLI arguments to use.
  # 
  # @return [Fixnum]
  #   The `ansible-playbook` command exit code.
  # 
  def self.setup args = []
    project_root = NRSER.git_root '.'
    playbook_path = project_root / 'dev' / 'setup.qb.yml'
    
    unless playbook_path.file?
      raise "Can't find QB setup playbook at `#{ playbook_path.to_s }`"
    end
    
    cmd = QB::Ansible::Cmds::Playbook.new \
      chdir: project_root,
      extra_vars: {
        project_root: project_root,
        qb_dir: project_root,
        qb_cwd: Pathname.getwd,
        qb_user_roles_dir: QB::USER_ROLES_DIR,
      },
      playbook_path: playbook_path
    
    puts cmd.prepare
    
    status = cmd.stream
    
    if status != 0
      $stderr.puts "ERROR QB setup failed."
    end
    
    exit status
    
  end # .setup
  
end # module QB::CLI
