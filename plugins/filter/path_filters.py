"""
Path manipulation filters using Python's `pathlib` module:

https://docs.python.org/dev/library/pathlib.html

as well as the `os.path` stdlib module.

Provided to Python 2.7 via the `pathlib2` pip module.
"""

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import sys
import re
import os
from pathlib2 import Path

from ansible.errors import AnsibleError

# def cap(string):
#     '''just upper-case the first damn letter.
#     
#     >>> cap("DoSomething")
#     'DoSomething'
#     
#     >>> cap('doSomething')
#     'DoSomething'
#     '''
#     return string[0].upper() + string[1:]


def resolve(*path_segments):
    '''
    Path resolution like I know from Node's `path.resolve`, but using Python's
    `pathlib.Path#resolve`, which seems to function the same way.
    
    Backported into 2.7 via the `pathlib2` pip modules.
    
    Joins paths right-to-left until they form an absolute path. If none is
    formed, the path is prefixed by the current directory to form an absolute 
    path.
    
    The resuling string is absolute and normalized.
    '''
    
    return Path(*path_segments).resolve().__str__()


def upcase_filename(path):
    '''
    Implemented pretty much just for `qb/osx/git/change_case` role...
    just upcase the file (or directory) name at `path`, leaving any "normal"
    file extension as is (will prob fuck up in weird file extension cases).
    
    >>> upcase_filename('./a.txt')
    './A.txt'
    
    >>> upcase_filename('./a/b.txt')
    './a/B.txt'
    
    >>> upcase_filename('./a')
    './A'
    
    >>> upcase_filename('./a/b')
    './a/B'
    
    >>> upcase_filename('./a.b.txt')
    './A.B.txt'
    
    >>> upcase_filename('./products/sg-v1/')
    './products/SG-V1'
    
    >>> upcase_filename('./products/sg-v1')
    './products/SG-V1'
    '''
    
    head, ext = os.path.splitext(path.strip('/'))
    dirname = os.path.dirname(head)
    filename = os.path.basename(head)
    return os.path.join(dirname, filename.upper() + ext)


def chomp_ext(path):
    '''
    >>> chomp_ext('google_appengine_1.9.23.zip')
    'google_appengine_1.9.23'

    >>> chomp_ext('bash-4.4.18.tar.gz')
    'bash-4.4.18'
    '''

    r = re.compile('\.tar\.\w{2,3}\Z')

    if r.search(path):
        return r.sub('', path)
    
    return os.path.splitext(path)[0]


class FilterModule(object):
    '''
    Path manipulation filter via Python's os.path module.
    '''

    def filters(self):
        return {
            'path_join': os.path.join,
            'path_resolve': resolve,
            'path_upcase_filename': upcase_filename,
        }


# testing - call camel_case on first cli arg and print result
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    