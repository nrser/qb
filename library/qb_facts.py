#!/usr/bin/python

import subprocess
import os
import glob
import json

def gemspec_path(dir):
    paths = glob.glob(os.path.join(dir, '*.gemspec'))
    
    if len(paths) == 0:
        return None
    elif len(paths) == 1:
        return paths[0]
    else:
        # this shouldn't really happen, but i don't want to stop the show...
        return paths[0]

def is_gem(dir):
    return bool(gemspec_path(dir))

def main():
    module = AnsibleModule(
        argument_spec = dict(
            qb_dir = dict(require = True, type = 'path'),
        ),
        supports_check_mode = False,
    )
    
    qb_dir = module.params['qb_dir']
    
    facts = {}
    
    cmds = {
        'qb_git_user_name': ['git', 'config', 'user.name'],
        'qb_git_user_email': ['git', 'config', 'user.email'],
        'qb_git_repo_root': ['git', 'rev-parse', '--show-toplevel'],
    }
    
    for key, cmd in cmds.iteritems():        
        try:
            value = subprocess.check_output(cmd).rstrip()
            facts[key] = value
        except subprocess.CalledProcessError as e:
            pass
    
    if is_gem(qb_dir):
        ruby = '''
            require 'json'
            spec = Gem::Specification::load("%s")
            puts JSON.dump({
                'name' => spec.name,
                'version' => spec.version,
            })
        ''' % (gemspec_path(qb_dir))
        
        spec_json = subprocess.check_output(['ruby', '-e', ruby])
        gem_info = json.loads(spec_json)
        gem_info['gemspec_path'] = gemspec_path(qb_dir)
        
        facts['qb_gem_info'] = gem_info
    
    # depreciated namespaceless names
    facts['git_user_name'] = facts['qb_git_user_name']
    facts['git_user_email'] = facts['qb_git_user_email']
    facts['git_repo_root'] = facts['qb_git_repo_root']
    
    changed = False

    module.exit_json(
        changed = changed,
        ansible_facts = facts,
    )

# import module snippets
from ansible.module_utils.basic import *
from ansible.module_utils.known_hosts import *

if __name__ == '__main__':
    main()