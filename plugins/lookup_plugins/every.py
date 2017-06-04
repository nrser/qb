"""
DOCUMENTATION:
    lookup: every
    version_added: "QB-0.1.61"
    short_description: Returns true for a key every X time delta (per host).
    description:
        -   Returns `True` if more than a specified amount of time has passed
            since it last returned `True` for that key for the current
            `inventory_hostname` fact.
            
            If it's never returned `True` for the `key` / `inventory_hostname`
            combo it will.
            
            This is useful to control updating - things like "run 
            `apt-get update` if it doesn't look like it's been run in a day",
            etcetera.
            
            ** WARNING: NOT AT ALL THREAD / CONCURRENCY SAFE **
            
            This is meant for things that you're *rather not* have run too
            often, it is not indented for and should not be used for
            controlling stuff that *must not* be run more than a certain
            frequency because it's a shit-simple implementation with 
            **NO LOCKING / CONCURRENCY SUPPORT** so if another thread or
            process is trying to do the same thing at the same time they will
            potentially both return `True` or who really knows what else.
            
            Data is stored at `~/.ansible/qb/data/every.yml`. This should 
            probably be configurable for for the moment it will do.
            
    options:
        key:
            description:
                -   Required single positional argument, used as the key to
                    store / retrieve data.
            required: True
        **kwargs:
            description:
                -   Accepts all the Python `datetime.timedelta` constructor
                    keywords. Requires at least one.
                     
                    You can set the delta to zero (so it returns True every
                    call) by providing `days=0` or similar (useful to test
                    stuff out maybe).
            required: True
EXAMPLES:

    -   name: Install Yarn via Homebrew, updating Homebrew at most once per day
        homebrew:
            name: yarn
            update_homebrew: "{{ lookup('every', 'update_homebrew' days=1) }}"

RETURN:

    `True` if it's been more than the provided period since the lookup returned
    `True` last for this key / 
    
"""

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.errors import AnsibleError
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
    """
    Can't believe Python doesn't have this built-in...
    """
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise


class LookupModule(LookupBase):
    def run(self, terms, variables=None, **kwargs):
        # Check args
        
        if len(terms) != 1:
            raise AnsibleError(
                "Requires exacty one positional argument (key)."
            )
        
        if len(kwargs) == 0:
            raise AnsibleError(
                "Requires at least one Python timedelta keyword arg."
            )
        
        # Setup variables
        
        key = terms[0]
        host = variables['inventory_hostname']
        
        data_path = os.path.join(
            variables['ansible_env']['HOME'],
            '.ansible',
            'qb',
            'data',
            'every.yml'
        )
        
        delta = timedelta(**kwargs)
        now = datetime.now()
        
        # Default to empty data
        data = {}
        
        # No idea how / where to see this output...
        # display.debug("Seeing if %s has been done in last %s" % (key, delta))
        
        # Ensure the data directory exists
        mkdir_p(os.path.dirname(data_path))
        
        # Read the data file, overwriting `data` var (if file it exists)
        try:
            with open(data_path, 'r') as f:
                data = yaml.safe_load(f)
        except IOError as error:
            pass 
        
        # If there's no entry for this host default to empty dict
        if host not in data:
            data[host] = {}
        
        # Default `should` (our return value) to True: if it's never returned
        # `True` it will now.
        should = True
        
        # If we have `data[host][key]['last']`, see if's been at least `delta`
        # and set `should`
        if key in data[host]:
            if 'last' in data[host][key]:
                should = (now - delta) >= data[host][key]['last']
        else:
            # Create a new dict at `data[host][key]` so we can write `now` to 
            # it
            data[host][key] = {}
        
        # If we're gonna return `True`, set `last` to `now` and write back 
        # to the path.
        # 
        # WARNING Not at all thread / concurrency safe!
        if should:
            data[host][key]['last'] = now
            
            with open(data_path, 'w') as f:
                yaml.safe_dump(data, f, default_flow_style=False)
        
        # And return our result
        return should
