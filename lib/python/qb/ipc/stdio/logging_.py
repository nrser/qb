import logging
import threading
import json

import qb.ipc.stdio

def getLogger(name, level=logging.INFO, io_client=qb.ipc.stdio.client):
    logger = logging.getLogger(name)
    if level is not None:
        logger.setLevel(level)
    logger.addHandler(Handler(io_client=io_client))
    return logger

class Handler(logging.Handler):
    """
    A handler class which writes logging records, in pickle format, to
    a streaming socket. The socket is kept open across logging calls.
    If the peer resets it, an attempt is made to reconnect on the next call.
    The pickle which is sent is that of the LogRecord's attribute dictionary
    (__dict__), so that the receiver does not need to have the logging module
    installed in order to process the logging event.
    To unpickle the record at the receiving end into a LogRecord, use the
    makeLogRecord function.
    """

    def __init__(self, io_client=qb.ipc.stdio.client):
        """
        Initializes the handler with a specific host address and port.
        The attribute 'closeOnError' is set to 1 - which means that if
        a socket error occurs, the socket is silently closed and then
        reopened on the next logging call.
        """
        logging.Handler.__init__(self)
        
        self.io_client = io_client
        
        # self.closeOnError = 0
        # self.retryTime = None
        # #
        # # Exponential backoff parameters.
        # #
        # self.retryStart = 1.0
        # self.retryMax = 30.0
        # self.retryFactor = 2.0

    # def createSocket(self):
    #     """
    #     Try to create a socket, using an exponential backoff with
    #     a max retry time. Thanks to Robert Olson for the original patch
    #     (SF #815911) which has been slightly refactored.
    #     """
    #     now = time.time()
    #     # Either retryTime is None, in which case this
    #     # is the first time back after a disconnect, or
    #     # we've waited long enough.
    #     if self.retryTime is None:
    #         attempt = 1
    #     else:
    #         attempt = (now >= self.retryTime)
    #     if attempt:
    #         try:
    #             self.sock = self.makeSocket()
    #             self.retryTime = None # next time, no delay before trying
    #         except socket.error:
    #             #Creation failed, so set the retry time and return.
    #             if self.retryTime is None:
    #                 self.retryPeriod = self.retryStart
    #             else:
    #                 self.retryPeriod = self.retryPeriod * self.retryFactor
    #                 if self.retryPeriod > self.retryMax:
    #                     self.retryPeriod = self.retryMax
    #             self.retryTime = now + self.retryPeriod

    def send(self, string):
        """
        Send a pickled string to the socket.
        This function allows for partial sends which can happen when the
        network is busy.
        """
        
        if not self.io_client.log.connected:
            return
        
        if not string.endswith( u"\n" ):
            string = string + u"\n"
        
        self.io_client.log.socket.sendall(string)
        # self.io_client.log.socket.flush()
        
        #self.sock can be None either because we haven't reached the retry
        #time yet, or because we have reached the retry time and retried,
        #but are still unable to connect.
        # if self.sock:
        #     try:
        #         if hasattr(self.sock, "sendall"):
        #             self.sock.sendall(s)
        #         else:
        #             sentsofar = 0
        #             left = len(s)
        #             while left > 0:
        #                 sent = self.sock.send(s[sentsofar:])
        #                 sentsofar = sentsofar + sent
        #                 left = left - sent
        #     except socket.error:
        #         self.sock.close()
        #         self.sock = None  # so we can call createSocket next time

    def makePickle(self, record):
        """
        Pickles the record in binary format with a length prefix, and
        returns it ready for transmission across the socket.
        """
        ei = record.exc_info
        if ei:
            # just to get traceback text into record.exc_text ...
            dummy = self.format(record)
            record.exc_info = None  # to avoid Unpickleable error
        # See issue #14436: If msg or args are objects, they may not be
        # available on the receiving end. So we convert the msg % args
        # to a string, save it as msg and zap the args.
        d = dict(record.__dict__)
        d['msg'] = record.getMessage()
        d['args'] = None
        s = cPickle.dumps(d, 1)
        if ei:
            record.exc_info = ei  # for next handler
        slen = struct.pack(">L", len(s))
        return slen + s

    def handleError(self, record):
        """
        Handle an error during logging.
        An error has occurred during logging. Most likely cause -
        connection lost. Close the socket so that we can retry on the
        next event.
        """
        # if self.closeOnError and self.sock:
        #     self.sock.close()
        #     self.sock = None        #try to reconnect next time
        # else:
        #     logging.Handler.handleError(self, record)
        
        # Just go up to super
        logging.Handler.handleError(self, record)
    
    def get_sem_log_level(self, level):
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
        
        self.format(record)
        
        try:
            struct = dict(
                level   = self.get_sem_log_level(record.levelname),
                name    = record.name,
                pid     = record.process,
                # thread  = threading.current_thread().name,
                thread  = record.threadName,
                message = record.message,
                # timestamp = record.asctime,
            )
            
            # if isinstance(record.args, dict):
            #     struct['payload'] = record.args
            # elif record.args:
            #     struct['payload'] = dict(args=record.args)
            
            if 'payload' in record.__dict__:
                struct['payload'] = record.__dict__['payload']
            
            string = json.dumps(struct)
            self.send(string)
        except (KeyboardInterrupt, SystemExit):
            raise
        except:
            raise
            # self.handleError(record)

    def close(self):
        """
        Closes the socket.
        """
        # self.acquire()
        # try:
        #     sock = self.sock
        #     if sock:
        #         self.sock = None
        #         sock.close()
        # finally:
        #     self.release()
        logging.Handler.close(self)
