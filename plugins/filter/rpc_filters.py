##
# Dynamically loads filters that are available in QB (Ruby) through RPC calls.
# 
# Does an RPC call it's self to get the mapping and coverts it a map of 
# lambdas for {FilterModule}.
# 
# Also adds the `send` filter to invoke arbitrary Ruby methods over RPC.
# 
##

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
import sys

from ansible.errors import AnsibleError

from qb import logging

from qb.ansible.display_handler import DisplayHandler
DisplayHandler.enable()
logger = logging.getLogger('plugins/filter/rpc_filters')


from qb.ipc.rpc import client


def qb_send(*args, **kwds):
    logger.warning(
        "DEPRECIATED - `qb_send` has been renamed `send`"
    )
    return client.send(*args, **kwds)


def qb_send_const(*args, **kwds):
    logger.warning(
        "DEPRECIATED - `qb_send_const` has been renamed `send`"
    )
    return client.send(*args, **kwds)


def _make_sender(receiver, method):
    '''
    Need this because Python `for` does not create a new variable or scope
    or whatever so lambdas inside them just bind by reference, resulting 
    in all the lambdas evaluating the loop variables to the last iteration.

    :rtype:     lambda
    :return:    A lambda that sends `*args* and `**kwds` to the receiver's
                method on the QB RPC server.
    '''

    return lambda *args, **kwds: client.send(
        receiver,
        method,
        *args,
        **kwds
    )


def get_map():
    data_map = client.get('/plugins/filters')

    filter_map = {}

    for filter_name, payload in data_map.iteritems():
        filter_map[filter_name] = _make_sender(
            payload['receiver'],
            payload['method']
        )

    # Add the `send` filter itself    
    filter_map['send'] = client.send

    # And it's old depreciated names...
    filter_map['qb_send'] = qb_send
    filter_map['qb_send_const'] = qb_send_const
    
    return filter_map


# Calling get_map() this at top-level causes doctest to fail... not sure why it
# was here? Trying to just do it on-demand and cache the results...
_map = None

def get_map_cached():
    global _map
    if _map is None:
        _map = get_map()
    return _map


class FilterModule( object ):
    '''
    Ruby filters available via RPC with the QB master process.
    '''

    def filters( self ):
        # global _map
        # return _map
        return get_map_cached()
    # filters()
# FilterModule


# Testing with doctest - there are no doctests in here, and the file fails
# because the RPC server of course isn't present
# if __name__ == '__main__':
#     import doctest
#     doctest.testmod()
    
