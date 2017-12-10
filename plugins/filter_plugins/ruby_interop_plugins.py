from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
import sys

from ansible.errors import AnsibleError


HERE = os.path.dirname(os.path.realpath(__file__))

PROJECT_ROOT = os.path.realpath(
    os.path.join(
        HERE, # //plugins/filter_plugins
        '..', # //plugins
        '..', # //
    )
)

LIB_PYTHON_DIR = os.path.join( PROJECT_ROOT, 'lib', 'python' )

if not (LIB_PYTHON_DIR in sys.path):
    sys.path.insert(0, LIB_PYTHON_DIR)

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
    