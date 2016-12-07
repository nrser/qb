from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import sys
import re

from ansible.errors import AnsibleError

def cap(string):
    '''just upper-case the first damn letter.
    
    >>> cap("DoSomething")
    'DoSomething'
    
    >>> cap('doSomething')
    'DoSomething'
    '''
    return string[0].upper() + string[1:]
    

def words(string):
    '''break a string into words
    
    >>> words('git_submodule_update')
    ['git', 'submodule', 'update']
    
    >>> words("qb.DoSomething")
    ['qb', 'DoSomething']
    '''
    return re.split('[\W\_]+', string)


def camel_case(string):
    '''convert a name to camel case.
    
    >>> camel_case("git_submodule_update")
    'gitSubmoduleUpdate'
    
    >>> camel_case("git-submodule-update")
    'gitSubmoduleUpdate'
    
    >>> camel_case("qb.do_something")
    'qbDoSomething'
    
    >>> camel_case("qb.DoSomething")
    'qbDoSomething'
    '''
    w = words(string)
    return w[0] + "".join(cap(s) for s in w[1:])


def cap_camel_case(string):
    '''convert a string to camel case with a leading capital.
    
    >>> upper_camel_case("git_submodule_update")
    'GitSubmoduleUpdate'
    
    >>> upper_camel_case("git-submodule-update")
    'GitSubmoduleUpdate'
    
    >>> upper_camel_case("qb.do_something")
    'QbDoSomething'
    '''
    return cap(camel_case(string))


class FilterModule(object):
    ''' some string filters '''

    def filters(self):
        return {
            'cap': cap,
            'words': words,
            'camel_case': camel_case,
            'cap_camel_case': cap_camel_case,
            'class_case': cap_camel_case,
        }


# testing - call camel_case on first cli arg and print result
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    