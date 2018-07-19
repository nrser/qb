from __future__ import absolute_import, division, print_function
__metaclass__ = type

import logging
import qb.logging

# Find a Display if possible
try:
    from __main__ import display
except ImportError:
    try:
        from ansible.utils.display import Display
    except ImportError:
        display = None
    else:
        display = Display()


class DisplayHandler(logging.Handler):
    '''
    A handler class that writes messages to Ansible's
    `ansible.utils.display.Display`, which then writes them to the user output.

    Includes static methods that let it act as a sort of a singleton, with
    a single instance created on-demand.
    '''


    # Singleton instance
    _instance = None


    @staticmethod
    def getDisplay():
        '''
        Get the display instance, if we were able to import or create one.

        :rtype:     None
        :return:    No display could be found or created.
        
        :rtype:     ansible.util.display.Display
        :return:    The display we're using.
        '''
        return display
    # .getDisplay
    

    @staticmethod
    def getInstance():
        '''
        :rtype:     DisplayHandler
        :return:    The singleton instance.
        '''
        if DisplayHandler._instance is None:
            DisplayHandler._instance = DisplayHandler()
        return DisplayHandler._instance
    # .getInstance


    @staticmethod
    def enable():
        '''
        Enable logging to Ansible's display by sending {.getInstance()} to
        {qb.logging.addHandler()}.

        :raises:
        '''
        instance = DisplayHandler.getInstance()

        if instance.display is None:
            raise RuntimeError("No display available")

        return qb.logging.addHandler(instance)
    # .enable


    def disable():
        '''
        Disable logging to Ansible's display be sending {.getInstance()} to
        {qb.logging.removeHandler()}.
        '''
        return qb.logging.removeHandler(DisplayHandler.getInstance())
    # .disable


    def is_enabled():
        return qb.logging.hasHandler(DisplayHandler.getInstance())
    # .is_enabled


    def __init__(self, display=None):
        logging.Handler.__init__(self)

        if display is None:
            display = DisplayHandler.getDisplay()
        
        self.display = display
    # #__init__


    def emit(self, record):
        '''
        Overridden to send log records to Ansible's display.
        '''

        if self.display is None:
            # Nothing we can do, drop it
            return

        try:
            self.format(record)

            if record.levelname == 'DEBUG':
                self.display.debug(record.message)

            elif record.levelname == 'INFO':
                # `verbose` I guess?
                self.display.verbose(record.message)

            elif record.levelname == 'WARNING':
                self.display.warning(record.message)

            elif record.levelname == 'ERROR':
                self.display.error(record.message)

            elif record.levelname == 'CRITICAL':
                self.display.error("(CRITICAL) {}".format(record.message))

            else:
                pass
        except (KeyboardInterrupt, SystemExit):
            raise
        except:
            raise
            # self.handleError(record)
    # #emit