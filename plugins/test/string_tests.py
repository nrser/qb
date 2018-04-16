# Imports
# ============================================================================

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import sys
import re
import os

from ansible.errors import AnsibleError

def startswith(string, prefix):
    '''
    >>> startswith('bigfoot', 'big')
    True
    '''
    
    return string.startswith( prefix )


class TestModule(object):
    '''Some string filters'''
    
    def tests(self):
        return {
            'startswith': startswith,
            'startwith': startswith,
        }


# testing - call camel_case on first cli arg and print result
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    
