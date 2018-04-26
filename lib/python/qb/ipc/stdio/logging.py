from __future__ import absolute_import, division, print_function
__metaclass__ = type

import logging
import threading
import json

import qb.ipc.stdio


def getLogger(name, level=logging.DEBUG, io_client=qb.ipc.stdio.client):
    logger = logging.getLogger(name)
    if level is not None:
        logger.setLevel(level)
    logger.addHandler(Handler(io_client=io_client))
    return Adapter(logger, {})


class Adapter(logging.LoggerAdapter):
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


class Handler(logging.Handler):
    """
    A handler class which writes logging records to the QB master process
    via it's `QB::IPC::STDIO` system, if available.
    
    If QB's STDIO system is not available, discards the logs.
    
    Based on the Python stdlib's `SocketHandler`, though it ended up retaining
    almost nothing from it since it just proxies to
    :class:`qb.ipc.stdio.Client`, which does all the socket dirty-work.
    
    ..  note:
        This class **does not** connect the :class:`qb.ipc.stdio.Client`
        instance (which defaults to the 'global' :attr:`qb.ipc.stdio.client`
        instance - and that's what you should use unless you're testing or
        doing something weird).
        
        You need to connect the client somewhere else (before or after creating
        loggers is fine).
    
    """
    
    
    def __init__(self, io_client=qb.ipc.stdio.client):
        """
        Initializes the handler with a :class:`qb.ipc.stdio.Client`, which
        default to the 'global' one at :attr:`qb.ipc.stdio.client`. This should
        be fine for everything except testing.
        
        See note in class doc about connecting the client.
        
        :param io_client:   :class:`qb.ipc.stdio.Client`
        """
        
        logging.Handler.__init__(self)
        self.io_client = io_client
        
        
    def send(self, string):
        """
        Send a string to the :attr:`io_client`.
        """
        
        if not self.io_client.log.connected:
            return
        
        self.io_client.log.println(string)
    
    
    def get_sem_log_level(self, level):
        """
        Trade Python log level string for a Ruby SemnaticLogger one.
        """
        if level == 'DEBUG' or level == 'INFO' or level == 'ERROR':
            return level.lower()
        elif level == 'WARNING':
            return 'warn'
        elif level == 'CRITICAL':
            return 'fatal'
        else:
            return 'info'
    
    
    def emit(self, record):
        """
        Emit a record.
        Pickles the record and writes it to the socket in binary format.
        If there is an error with the socket, silently drop the packet.
        If there was a problem with the socket, re-establishes the
        socket.
        
        record: https://docs.python.org/2/library/logging.html#logrecord-attributes
        """
        
        try:
            self.format(record)
            
            struct = dict(
                level   = self.get_sem_log_level(record.levelname),
                name    = record.name,
                pid     = record.process,
                # thread  = threading.current_thread().name,
                thread  = record.threadName,
                message = record.message,
                # timestamp = record.asctime,
            )
            
            # The `logging` stdlib module allows you to add extra values
            # by providing a `extra` key to the `Logger#debug` call (and
            # friends), which it just adds to the the keys and values to the
            # `record` object's `#__dict__` (where they better not conflict
            # with anything else or you'll be in trouble I guess).
            # 
            # We look for a `payload` key in there.
            # 
            # Example logging with a payload:
            # 
            #       logger.debug("My message", extras=dict(payload=dict(x=1)))
            # 
            # Yeah, it sucks... TODO extend Logger or something to make it a
            # little easier to use?
            # 
            if 'payload' in record.__dict__:
                struct['payload'] = record.__dict__['payload']
            
            string = json.dumps(struct)
            self.send(string)
        except (KeyboardInterrupt, SystemExit):
            raise
        except:
            raise
            # self.handleError(record)
