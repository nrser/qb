# Imports
# ============================================================================

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import sys
import re
import os

from ansible.errors import AnsibleError
from jinja2.filters import contextfilter

def to_dict( value ):
    '''Call Python's built-in `dict()` on the value.
    
    Can't believe this shit isn't built-in to Jinja/Ansible :/
    '''
    
    return dict( value )


@contextfilter
def select_by_keys( context, dct, test_name, *args, **kwds ):
    # raise StandardError(
    #     "args: {}, kwds: {}".format( args, kwds )
    # )
    
    test = lambda key: context.environment.call_test(
        test_name, key, args, kwds
    )
    
    new_dct = {}
    
    for key, value in dct.iteritems():
        if test( key ):
            new_dct[key] = value
    
    return new_dct


class FilterModule(object):
    '''Some dict filters'''
    
    def filters(self):
        return {
            'dict': to_dict,
            'select_by_keys': select_by_keys,
        }


# testing - call camel_case on first cli arg and print result
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    
