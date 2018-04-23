from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
import sys

from ansible.errors import AnsibleError

import qb.interop


class FilterModule( object ):
    '''
    Ruby interop filters.
    '''

    def filters( self ):
        return {
            'qb_send':          qb.interop.send,
            'qb_send_const':    qb.interop.send_const,
        }
    # filters()
# FilterModule


# Testing with doctest
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    
