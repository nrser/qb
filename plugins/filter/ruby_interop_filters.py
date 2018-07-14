from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
import sys

from ansible.errors import AnsibleError

from qb import logging

from qb.ansible.display_handler import DisplayHandler
DisplayHandler.enable()
logger = logging.getLogger('ruby_interop_filters')

import qb.interop


class FilterModule( object ):
    '''
    Ruby interop filters.
    '''

    def filters( self ):
        return {
            'send':             qb.interop.send,
            'qb_send':          qb.interop.send,
            'qb_send_const':    qb.interop.send,
        }
    # filters()
# FilterModule


# Testing with doctest
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    
