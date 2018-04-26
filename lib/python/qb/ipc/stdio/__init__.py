from __future__ import absolute_import, division, print_function
__metaclass__ = type

import os
import socket

def path_env_var_name(name):
    return "QB_STDIO_{}".format(name.upper())


class Connection:
    '''
    Port of Ruby `QB::IPC::STDIO::Client::Connection` class.
    '''
    
    def __init__(self, name, type):
        self.name = name
        self.type = type
        self.path = None
        self.socket = None
        self.env_var_name = path_env_var_name(self.name)
        self.connected = False
    
    def __str__(self):
        attrs = ' '.join(
            "{}={}".format(name, getattr(self, name))
            for name in ('name', 'type', 'path', 'connected')
        )
        return "<qb.ipc.stdio.Connection {}>".format(attrs)
    
    def get_path(self):
        if self.env_var_name in os.environ:
            self.path = os.environ[self.env_var_name]
        return self.path
    
    def connect(self, warnings=None):
        if self.connected:
            raise RuntimeError("{} is already connected!".format(self))
        
        if self.get_path() is None:
            return False
        
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        
        try:
            self.socket.connect(self.path)
        except socket.error, msg:
            if warngings is not None:
                warning = 'Failed to connect to QB STDOUT stream at {}: {}'
                warning = warning.format(qb_stdout_path, msg)
                warnings.append(warning)
            
            self.socket = None
            return False
        
        self.connected = True
        
        return True
    
    def disconnect(self):
        if not self.connected:
            raise RuntimeError("{} is not connected!".format(self))
        
        # if self.type == 'out':
        #     self.socket.flush()
        
        self.socket.close()
        self.socket = None
        self.connected = False
        
    def println(self, line):
        if not line.endswith( u"\n" ):
            line = line + u"\n"
        self.socket.sendall(line.encode("utf-8"))
        

class Client:
    def __init__(self):
        # I don't think need STDIN or we want to deal with what it means here
        # self.stdin  = Connection(name='in', type='in')
        self.stdout = Connection(name='out', type='out')
        self.stderr = Connection(name='err', type='out')
        self.log    = Connection(name='log', type='out')
    
    def connections(self):
        return [self.stdout, self.stderr, self.log]
    
    def connect(self, warnings=None):
        for connection in self.connections():
            if not connection.connected:
                connection.connect(warnings)
        return self
    
    def disconnect(sefl):
        for connection in self.connections():
            if connection.connected:
                connection.disconnect()

client = Client()
