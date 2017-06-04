from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.errors import AnsibleError, AnsibleParserError
from ansible.plugins.lookup import LookupBase

try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()

from datetime import datetime, timedelta
import os
import errno
import yaml

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        key = terms[0]
        host = variables['inventory_hostname']
        
        # no idea how / where to see this output...
        # display.debug("Seeing if %s has been done in last %s" % (key, delta))
        
        data_path = os.path.join(
            variables['ansible_env']['HOME'],
            '.ansible',
            'qb',
            'data',
            'every.yml'
        )
        
        mkdir_p(os.path.dirname(data_path))
        
        delta = timedelta(**kwargs)
        
        data = {}
        now = datetime.now()
        
        try:
            with open(data_path, 'r') as f:
                data = yaml.safe_load(f)
        except IOError as error:
            pass 
        
        if host not in data:
            data[host] = {}
        
        host_data = data[host]
        
        should = True
        
        if key in host_data:
            if 'last' in host_data[key]:
                should = (now - delta) > host_data[key]['last']
        else:
            host_data[key] = {}
        
        if should:
            host_data[key]['last'] = now
            
            with open(data_path, 'w') as f:
                yaml.safe_dump(data, f, default_flow_style=False)
        
        return should
