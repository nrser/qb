#!/usr/bin/python

import subprocess
import os
import glob
import json
import re

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
    if dir is None:
        return False
        
    return dir and bool(gemspec_path(dir))


def package_json_path(dir):
    return os.path.join(dir, 'package.json')


def has_package_json(dir):
    if dir is None:
        return False
    
    return os.path.isfile(package_json_path(dir))


def main():
    module = AnsibleModule(
        argument_spec = dict(
            qb_dir = dict(require = False, type = 'path'),
        ),
        supports_check_mode = False,
    )
    
    qb_dir = module.params['qb_dir']
    
    facts = {}
    
    cmds = {
        'qb_git_user_name': ['git', 'config', 'user.name'],
        'qb_git_user_email': ['git', 'config', 'user.email'],
        'qb_git_repo_root': ['git', 'rev-parse', '--show-toplevel'],
        'qb_git_origin_url': ['git', 'remote', 'get-url', 'origin'],
    }
    
    for key, cmd in cmds.iteritems():        
        try:
            value = subprocess.check_output(cmd).rstrip()
            facts[key] = value
            # depreciated old name
            facts[key[3:]] = value
        except subprocess.CalledProcessError as e:
            pass
    
    if facts['qb_git_origin_url']:
        # git@github.com:<owner>/<name>.git
        ssh_re = re.compile('^git@github\.com\:(.*)/(.*)\.git$')
        # https://github.com/<owner>/<name>.git
        https_re = re.compile('^https\://github\.com/(.*)/(.*)\.git$')
        
        ssh_match = ssh_re.match(facts['qb_git_origin_url'])
        https_match = https_re.match(facts['qb_git_origin_url'])
        
        if ssh_match:
            facts['qb_github_owner'] = ssh_match.group(1)
            facts['qb_github_name'] = ssh_match.group(2)
        elif https_match:
            facts['qb_github_owner'] = https_match.group(1)
            facts['qb_github_name'] = https_match.group(2)
        
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
    
    if has_package_json(qb_dir):
        f = open(package_json_path(qb_dir))
        package_json = json.loads(f.read())
        f.close()
        facts['qb_package_json'] = package_json
    
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