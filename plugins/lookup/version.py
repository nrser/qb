# Be more Python 3
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import sys
import os

from ansible.errors import AnsibleError, AnsibleParserError
from ansible.plugins.lookup import LookupBase

try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()

import qb.interop


class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        '''
        WARNING!!!  Lookup plugins need to return a *list*. Unclear why... but
                    you return a single value as [value].
        '''
        
        path = os.path.join(*terms)
        
        if not os.path.isabs(path):
            path = os.path.join(variables['qb_dir'], path)
        
        if not os.path.isfile(path):
            path_with_version = os.path.join(path, 'VERSION')
            
            if not os.path.isfile(path_with_version):
                raise AnsibleError(
                    "Neither path %s or %s exists" % (path, path_with_version)
                )
            
            path = path_with_version
        
        with open(path, 'r') as file:
            raw = file.read().strip()
            
            version = qb.interop.send_const(
                'QB::Package::Version',
                'from_string',
                raw,
            )
            
            # WARNING!!! **must** be a list:
            return [version]
