# Requirements
# =====================================================================

# StdLib
require 'pathname'

# package
require 'qb/ansible/cmds/playbook'


# Refinements
# =======================================================================

require 'nrser/refinements'
using NRSER


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
    # Figure out project root and setup playbook path
    case args[0]
    when String, Pathname
      # The playbook path has been provided, use that to find the project root
      playbook_path = QB::Util.resolve args[0]
      project_root = NRSER.git_root playbook_path
      
    when nil
      # Figure the project root out from the current directory, then
      # form the playbook path from that
      project_root = NRSER.git_root '.'
      playbook_path = project_root / 'dev' / 'setup.qb.yml'
    
    else
      raise TypeError.new binding.erb <<-END
        First entry of `args` must be nil, String or Pathname, found:
        
            <%= args[0].pretty_inspect %>
        
        args:
        
            <%= args.pretty_inspect %>
        
      END
    end
    
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
