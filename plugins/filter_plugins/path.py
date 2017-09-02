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
    

class FilterModule(object):
    '''
    Path manipualtion filter via Python's os.path module.
    '''

    def filters(self):
        return {
            'path_join': os.path.join,
            'path_resolve': resolve,
        }


# testing - call camel_case on first cli arg and print result
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    