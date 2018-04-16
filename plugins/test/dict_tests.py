# Imports
# ============================================================================

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import sys
import re
import os

from ansible.errors import AnsibleError

def key_prefix(key_and_value, prefix):
    '''
    
    >>> key_prefix(('key', 'value'), 'k')
    True
    '''
    
    return key_and_value[0].startswith(prefix)


class TestModule(object):
    '''Some dict filters'''
    
    def tests(self):
        return {
            'key_prefix': key_prefix,
        }


# testing - call camel_case on first cli arg and print result
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    
