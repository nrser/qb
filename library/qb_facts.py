#!/usr/bin/python

import subprocess

def main():
    module = AnsibleModule(
        argument_spec = dict(
        ),
        supports_check_mode = False,
    )

    
    facts = {}
    
    d = {
        'git_user_name': ['git', 'config', 'user.name'],
        'git_user_email': ['git', 'config', 'user.email'],
    }
    
    for key, cmd in d.iteritems():        
        try:
            facts[key] = subprocess.check_output(cmd).rstrip()
        except subprocess.CalledProcessError as e:
            pass        
        
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