#!/usr/bin/python

import os

def main():
    module = AnsibleModule(
        argument_spec = dict(
            path = dict(required=True, type='str'),
        ),
        supports_check_mode = False,
    )

    
    facts = {}
    changed = False
    
    path = module.params.get('path')
    path_parts = path.split('/')
    
    dir = os.path.join(*path_parts[:-1])
    dashed = "-".join(path_parts)
    class_name = "".join([s.capitalize() for s in path_parts])
    
    facts['component_dir'] = dir
    facts['component_dashed'] = dashed
    facts['component_class_name'] = class_name
    facts['component_logger_name'] = ":".join(['imports', 'ui'] + path_parts)

    module.exit_json(
        changed = changed,
        ansible_facts = facts,
    )

# import module snippets
from ansible.module_utils.basic import *
from ansible.module_utils.known_hosts import *

if __name__ == '__main__':
    main()