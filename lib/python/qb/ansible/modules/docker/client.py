#!/usr/bin/python
#
# Copyright 2016 Red Hat | Ansible
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

import json

from ansible.module_utils.docker_common import AnsibleDockerClient

import qb.ipc.stdio
import qb.ipc.stdio.logging


class QBAnsibleDockerClient(AnsibleDockerClient):
    
    # Construction
    # ========================================================================
    
    def __init__(self, *args, **kwds):
        self.logger = qb.ipc.stdio.logging.getLogger(
            'qb.ansible.modules.docker.client.QBAnsibleDockerClient'
        )
        
        AnsibleDockerClient.__init__(self, *args, **kwds)
        
    
    # Instance Methods
    # ============================================================================
    
    # Logging and Output
    # ----------------------------------------------------------------------------
    
    def out(self, msg):
        '''
        Write output from the Docker daemon to STDOUT for the user to see
        what's going on.
        
        This used to be called `log` and was used for more than just logging
        output from Docker, and it didn't do anything... though there was some
        commented out code to write to a file.
        
        Now it writes to the QB master process' STDOUT through
        `QB::IPC::STDOUT`, assuming that's present.
        
        :param msg  - A string or dict.
        
        :return:    None
        '''
        
        # Bail unless QB STDOUT is connected
        if not qb.ipc.stdio.client.stdout.connected:
            return None
        
        # What we're gonna write
        string = None
        
        if isinstance(msg, str):
            # If the message is just a string, write that
            string = msg
            
        elif isinstance( msg, dict ):
            # Dicts come for the Docker daemon/API, so we want to extract the
            # relevant output and display that nicely... work in progress
            
            if 'stream' in msg:
                # This is part of an output 'stream' from a build,
                # so just grab that that variable.
                string = msg['stream']
            
            elif 'status' in msg:
                # This is part of an output from a pull (and maybe more?)
                
                if 'id' in msg:
                    if 'progress' in msg:
                        string = "{id} {status} {progress}".format(**msg)
                    else:
                        string = "{id} {status}".format(**msg)
                else:
                    string = msg['status']
                
            else:
                # Structures we're not sure how to deal with yet... just
                # just pretty-dump them
                string = json.dumps(
                    msg,
                    sort_keys=True,
                    indent=4,
                    separators=(',', ': ')
                )
        else:
            self.logger.warning(
                "Unregonized `msg` type {} in .out", type(msg),
                payload=dict(msg=msg)
            )
        
        if string is not None:
            qb.ipc.stdio.client.stdout.println(string)
    
    
    def log(self, msg, pretty_print=False):
        '''
        Override :class:`AnsibleDockerClient.log` to actually do something.
        
        It's used in :class:`AnsibleDockerClient` to do *both* logging and
        relaying Docker API/daemon output, but we try to split it up and
        send logging to :attr:`logger` and output to :meth:`out` - output seems
        to always be `dict`, though this might be wrong.
        
        :param msg:             A stirng or dict.
        :param pretty_print:    Boolean, but not used - part of super API.
        
        :return:    None
        '''
        
        if isinstance(msg, dict):
            self.out(msg)
        elif isinstance(msg, str):
            self.logger.info(msg)
        else:
            self.logger.warning(
                "Unregonized `msg` type {} in .log".format(type(msg)),
                payload=dict(msg=msg)
            )
    
    
    def fail(self, msg, **values):
        '''
        Overrides :class:`AnsibleDockerClient.fail` to log the failure first
        (as `critical`/`fatal`).
        
        Also adds feature to accept a dict of values which will be
        :meth:`str.format` into the `msg` and also logged as the payload.
        
        :param msg:     String message, which may have `{key}` template markers
                        in it to be subsititued from `values`.
        :param values:  Optional dict of values to interpolate and log.
        
        :return:        See :class:`AnsibleDockerClient.fail`
        '''
        
        if values:
            msg = msg.format(**values)
        
        self.logger.critical(msg, payload=values)
        
        return super(QBAnsibleDockerClient, self).fail(msg)
    
    
    # Actions
    # ------------------------------------------------------------------------

    def try_pull_image(self, name, tag="latest"):
        '''
        Try to pull an image (before building or loading)
        '''
        
        self.logger.info(
            "Attempting to pull image {}:{}".format(name, tag)
        )
        
        try:
            for line in self.pull(name, tag=tag, stream=True, decode=True):
                self.out(line)
                
                if line.get('error'):
                    self.logger.info(
                        "Attempt to pull {}:{} failed".format(name, tag)
                    )
                    return None
                    
        except Exception as exc:
            self.logger.warning(
                "Error pulling image {}:{} - {}".format(name, tag, str(exc))
            )
            return None

        return self.find_image(name=name, tag=tag)
