##############################################################################
# 
##############################################################################

# Imports
# ============================================================================

# Make Python 3-ish 
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

# Stdlib
# ----------------------------------------------------------------------------

# Need {os.environ}, {os.path.join}
import os

# Need {urllib.quote_plus} to URL-encode socket paths for the 
# {requests_unixsocket} package.
import urllib

# Deps
# ----------------------------------------------------------------------------

# Facilities making requests to UNIX domain sockets with the {requests}
# package.
import requests_unixsocket


# Constants
# ============================================================================

# The name of the ENV var that holds the socket path, which is created in a
# temp dir that only exists while the main QB process is running and is only
# accessible to the user that ran it.
# 
RPC_SOCKET_ENV_VAR_NAME = 'QB_RPC_SOCKET'


# Module Variables
# ============================================================================

# A "module-level global" (yeah, weird they're called "globals") that holds 
# the default {Client}, which is created on demand.
# 
# Need to preface it's use with
# 
#       global _client
# 
_client = None


# Module Functions
# ============================================================================
#
# Static helpers and functions that operate on the default {Client}, which is
# created on demand using the ENV var set by the QB master process that hosts
# the server (during normal execution... things are set up flexibly because I'm
# sure we'd want to do things differently during testing).
#
# NOTE  Due to the way Python's files<->imports system works, this seems like
#       the least annoying way to create a decent API without sticking stuff in
#       the `__init__.py` file, which I *hate* because it's really hard to
#       remember which ones have shit in them.
#

def client_from_env():
    return Client(socket_path=os.environ[RPC_SOCKET_ENV_VAR_NAME])


def requests_path_for(socket_path):
    '''
    URL-quotes the socket file path and protocol prefixes it with `http+unix://`

    The {requests} module - as extended by {requests_unixsocket} - requires that
    the actual file path to the socket by URL-quoted, probably because it uses
    some split-by-/ logic to parse it, which would normally consider the socket
    path part of the HTTP path.

    :rtype:     str
    :return:    Path ready for use with {requests_unixsocket.Session}.
    '''
    return "http+unix://{}".format(urllib.quote_plus(socket_path))


def init_from_env(force=False):
    global _client

    if _client is None or force is True:
        _client = client_from_env()
        return True
    else:
        return False


def get_client():
    global _client
    init_from_env()
    return _client


def set_client(client):
    global _client
    _client = client


def get(path):
    return get_client().get(path)


def post(path, **payload):
    return get_client().post(path, **payload)


def send(receiver, method, *args, **kwds):
    return get_client().send(receiver, method, *args, **kwds)


class Client:
    '''
    RPC client for making calls to the QB master Ruby process (HTTP over 
    a UNIX domain socket).
    '''

    def __init__(self, socket_path):
        self.socket_path = socket_path
        self.session = requests_unixsocket.Session()
        self.requests_path = requests_path_for(self.socket_path)


    def full_path_for(self, path):
        if path[0] == '/':
            path = path[1:]
        return os.path.join(self.requests_path, path)


    def handle_response(self, response):
        return response.json()['data']


    def get(self, path):
        return self.handle_response(
            self.session.get(
                self.full_path_for(path)
            )
        )
    

    def post(self, path, **payload):
        return self.handle_response(
            self.session.post(
                self.full_path_for(path),
                json = payload,
            )
        )
    
    
    def send(self, receiver, method, *args, **kwds):
        return self.handle_response(
            self.session.post(
                self.full_path_for('/send'),
                json = dict(
                    receiver = receiver,
                    method = method,
                    args = args,
                    kwds = kwds,
                )
            )
        )

