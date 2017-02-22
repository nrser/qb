from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import subprocess
import os

from ansible.errors import AnsibleError


QB_ROOT = os.path.realpath(
    os.path.join(
        os.path.dirname(os.path.realpath(__file__)), # /plugins/filter_plugins
        '..', # /plugins
        '..', # /
    )
)


def semver_inc(version, level = None, preid = None):
    '''increment the version at level, with optional preid for pre- levels.
    
    runs
    
        semver --increment <level> [--preid <preid>] <version>
    
    >>> semver_inc('1.0.0', 'minor', preid = 'dev')
    '1.0.1-dev.0'
    
    '''
    
    cmd = [
        os.path.join(QB_ROOT, 'node_modules', '.bin', 'semver'),
        '--increment',
    ]
    
    if not (level is None):
        cmd.append(level)
    
    if not (preid is None):
        cmd.append('--preid')
        cmd.append(preid)
    
    cmd.append(version)
    
    out = subprocess.check_output(cmd)
    
    return out.rstrip()


class FilterModule(object):
    ''' version manipulation filters '''

    def filters(self):
        return {
            'semver_inc': semver_inc,
        }


# testing - call camel_case on first cli arg and print result
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    