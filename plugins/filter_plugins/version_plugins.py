from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import subprocess
import os
import json

from ansible.errors import AnsibleError


QB_ROOT = os.path.realpath(
    os.path.join(
        os.path.dirname(os.path.realpath(__file__)), # /plugins/filter_plugins
        '..', # /plugins
        '..', # /
    )
)


def get_semver_path():
    bin_path = os.path.join(QB_ROOT, 'node_modules', 'semver', 'bin', 'semver')
    
    if not os.path.isfile(bin_path):
        raise Exception("can't find semver at %s" % bin_path)
    
    return bin_path 
# get_semver_path()


def semver_inc(version, level = None, preid = None):
    '''increment the version at level, with optional preid for pre- levels.
    
    runs
    
        semver --increment <level> [--preid <preid>] <version>
    
    >>> semver_inc('1.0.0', 'minor', preid = 'dev')
    '1.0.1-dev.0'
    
    '''

    cmd = [
        get_semver_path(),
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
# semver_inc()


def semver_parse(version):
    '''parse semver.
    '''
    
    stmt = (
        '''console.log(JSON.stringify(require('semver')(%s), null, 2))''' %
        json.dumps(version)
    )
    
    cmd = ['node', '--eval', stmt]
    
    out = subprocess.check_output(
        cmd,
        cwd = QB_ROOT
    )
    
    version = json.loads(out)
    
    version['is_release'] = len(version['prerelease']) == 0
    
    version['is_dev'] = (
        len(version['prerelease']) > 0 and
        version['prerelease'][0] == 'dev'
    )
    
    version['is_rc'] = (
        len(version['prerelease']) > 0 and
        version['prerelease'][0] == 'rc'
    )
    
    if version['is_release']:
        version['level'] = 'release'
    else:
        version['level'] = version['prerelease'][0]
    
    # depreciated name for level
    version['type'] = version['level']
    
    version['release'] = "%(major)s.%(minor)s.%(patch)s" % version
    
    return version
# semver_parse()


def qb_version_parse(version_string):
    '''Parse version into QB::Package::Version
    '''
    
    ruby_code = (
        '''
        require 'qb'
        
        puts JSON.dump(
            QB::Package::Version.from_string %s
        )
        ''' % json.dumps(version_string)
    )
    
    cmd = ['/usr/bin/env', 'ruby', '-e', ruby_code]
    
    out = subprocess.check_output(cmd)
    
    version = json.loads(out)
    
    return version


def qb_read_version(file_path):
    '''Read a QB::Package::Version from a file.
    '''
    
    with open(file_path, 'r') as file:
        return qb_version_parse(file.read())
    

class FilterModule(object):
    ''' version manipulation filters '''

    def filters(self):
        return {
            'semver_inc': semver_inc,
            'semver_parse': semver_parse,
            'qb_version_parse': qb_version_parse,
            'qb_read_version': qb_read_version,
        }
    # filters()
# FilterModule


# testing - call camel_case on first cli arg and print result
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    