# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# ========================================================================

### Stdlib ###

require 'pathname'

### Project / Package ###

# Will use {QB::Ansible::Cmd::Playbook} to run the playbook!
require 'qb/ansible/cmd/playbook'


# Namespace
# ========================================================================

module QB
module CLI


# Definitions
# =======================================================================

# Run a setup playbook.
# 
# The path to the setup playbook can be given as the first of `args`, or 
# `setup.qb.{yaml,yml}` will be searched in `$REPO_ROOT/dev/` and 
# `$REPO_ROOT/`, where `$REPO_ROOT` is the Git root for the current directory.
# 
# @todo
#   1.  While it works, this system of finding the setup files feels kind-of 
#       wonky.
#   2.  Any additional entries in `args` after the first seem to be silently
#       ignored. Seems like we should do something with them (run all of them?)
#       or error.
# 
# @param [Array<String>] args
#   Either:
#   
#   1.  Empty, in which case we search for the setup playbook as detailed above.
#   2.  Contains a single path to the setup playbook.
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
    
    playbook_path = Util.find_yaml_file! \
      dirs: [
        project_root.join( 'dev' ),
        project_root,
      ],
      basename: 'setup.qb'
  
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
  
  cmd = QB::Ansible::Cmd::Playbook.new \
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


# /Namespace
# ========================================================================

end # module CLI
end # module QB
