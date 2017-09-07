from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.errors import AnsibleError

import subprocess
import yaml
from ansible.parsing.yaml.dumper import AnsibleDumper

def qb_send(data, method, *args, **kwds):
    '''
    Load data as an object in ruby and send it a message (call a method).
    '''
    
    payload = {
        'data': data,
        'method': method,
        'args': args,
        'kwds': kwds,
    }
    
    input = yaml.dump(payload, Dumper=AnsibleDumper)
    
    ruby_code = '''
        # init bundler in dev env
        if ENV['QB_DEV_ENV']
            ENV.each {|k, v|
                if k.start_with? 'QB_DEV_ENV_'
                    ENV[k.sub('QB_DEV_ENV_', '')] = v
                end
            }
            require 'bundler/setup'
        end
        
        require 'qb'
        
        QB::Util::Interop.receive
    '''
    
    process = subprocess.Popen(
        ['/usr/bin/env', 'ruby', '-e', ruby_code],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    
    out, err = process.communicate(input)
    
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
    

class FilterModule(object):
    '''
    Ruby interop filters.
    '''

    def filters(self):
        return {
            'qb_send': qb_send,
        }
    # filters()
# FilterModule


# testing - call camel_case on first cli arg and print result
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    