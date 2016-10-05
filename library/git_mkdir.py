#!/usr/bin/python

# import some python modules that we'll use.  These are all
# available in Python's core

import datetime
import sys
import json
import os
import shlex
import errno
import subprocess
import contextlib

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

def contians_files(path):
    for dirpath, dirnames, filenames in os.walk(path):
        if len(filenames) > 0:
            return True

@contextlib.contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        os.chdir(prevdir)

def main():
    module = AnsibleModule(
        argument_spec = dict(
            path=dict(required = True),
            commit=dict(required = False, default = False, type = 'bool'),
        ),
        supports_check_mode = False,
    )
    
    changed = False
    path = module.params['path']
    commit = module.params['commit']
    
    if os.path.isdir(path) is False:
        mkdir_p(path)
        changed = True
    
    keep_path = os.path.join(path, '.gitkeep')
    
    if (not os.path.exists(keep_path)) and (not contians_files(path)):
        open(os.path.join(path, '.gitkeep'), 'a').close()
        if commit is True:
            with cd(path):
                subprocess.check_call(['git', 'add', '-f', '.gitkeep'])
        changed = True

    module.exit_json(
        changed = changed,
    )

# import module snippets
from ansible.module_utils.basic import *
from ansible.module_utils.known_hosts import *

if __name__ == '__main__':
    main()