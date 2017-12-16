from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.errors import AnsibleError

import subprocess
import yaml
import os
from ansible.parsing.yaml.dumper import AnsibleDumper


QB_ROOT = os.path.realpath(
    os.path.join(
        os.path.dirname(os.path.realpath(__file__)), # //lib/python/qb
        '..', # //lib/python
        '..', # //lib
        '..', # //
    )
)

INTEROP_RECEIVE_EXE = os.path.join( QB_ROOT, 'exe', '.qb_interop_receive' )


def send_payload( payload ):
    '''
    Send a payload to QB Ruby code via a subprocess.
    '''
    
    input = yaml.dump( payload, Dumper=AnsibleDumper )
    
    process = subprocess.Popen(
        [ INTEROP_RECEIVE_EXE ],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=os.environ,
    )
    
    out, err = process.communicate( input )
    
    if process.returncode != 0:
        raise AnsibleError('''
            qb_send failed!
            
            ERROR:
                %s
        ''' % (err))
    
    try:
        result = yaml.safe_load(out)
    except Exception as error:
        raise AnsibleError('''
            qb_send failed to parse response:
            
            %s
        ''' % out)
    
    return result


def send( data, method, *args, **kwds ):
    '''
    Load data as an object in ruby and send it a message (call a method).
    '''
    
    return send_payload({
        'data': data,
        'method': method,
        'args': args,
        'kwds': kwds,
    })


def send_const( name, method, *args, **kwds ):
    '''
    Send a message (call a method) to a Ruby constant by name.
    '''
    
    return send_payload({
        'const': name,
        'method': method,
        'args': args,
        'kwds': kwds,
    })


# Testing with doctest
if __name__ == '__main__':
    import doctest
    doctest.testmod()