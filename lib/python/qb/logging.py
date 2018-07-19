from __future__ import absolute_import, division, print_function
__metaclass__ = type

import logging
import threading
import json
import weakref

import qb.ipc.stdio

# Current handlers
_handlers = []


def hasHandler(handler):
    return handler in _handlers
# hasHandler


def addHandler(handler):
    '''
    Add a handler if it's not already added.

    :rtype:     Boolean
    :return:    `True` if it was added (not already there), `False` if already
                present.
    '''
    if not handler in _handlers:
        _handlers.append(handler)
        return True
    else:
        return False
# addHandler


def removeHandler(handler):
    '''
    Remove a handler.

    :rtype:     Boolean
    :return:    `True` if it was removed, `False` if wasn't  there to begin
                with.
    '''
    if handler in _handlers:
        _handlers.remove(handler)
        return True
    else:
        return False
# removeHandler


def getLogger(name, level=logging.DEBUG):
    logger = logging.getLogger(name)
    if level is not None:
        logger.setLevel(level)
    for handler in _handlers:
        logger.addHandler(handler)
    return Adapter(logger, {})


class Adapter(logging.LoggerAdapter):
    '''
    Adapter to allow Ruby's Semantic Logger (basis of NRSER::Log) style logging,
    which is then easy to translate when sending logs up to the QB master
    process via IPC.

    Usage:

        logger.info(
            "Message with payload {value} interpolations",
            payload = dict(
                value = "interpolated into message",
                mote = "values",
                # ...
            )
        )

    '''
    
    def process(self, msg, kwds):
        payload = None
        if 'payload' in kwds:
            payload = kwds['payload']
            del kwds['payload']
        
        if payload:
            try:
                msg = msg.format(**payload)
            except:
                pass
            
            if 'extra' not in kwds:
                kwds['extra'] = {}
            
            kwds['extra']['payload'] = payload
            
        return msg, kwds
