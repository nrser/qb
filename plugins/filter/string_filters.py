# **WARNING**
# 
# Naming this file `string.py` fucks something up:
# 
#       $ python2 plugins/filter_plugins/path.py
#       Traceback (most recent call last):
#         File "plugins/filter_plugins/path.py", line 17, in <module>
#           from pathlib2 import Path
#         File "/usr/local/lib/python2.7/site-packages/pathlib2.py", line 21, in <module>
#           from urllib import quote as urlquote_from_bytes
#         File "/usr/local/Cellar/python/2.7.13_1/Frameworks/Python.framework/Versions/2.7/lib/python2.7/urllib.py", line 30, in <module>
#           import base64
#         File "/usr/local/Cellar/python/2.7.13_1/Frameworks/Python.framework/Versions/2.7/lib/python2.7/base64.py", line 98, in <module>
#           _urlsafe_encode_translation = string.maketrans(b'+/', b'-_')
#       AttributeError: 'module' object has no attribute 'maketrans'
# 
# https://stackoverflow.com/questions/35139025/can-not-handle-attributeerror-module-object-has-no-attribute-maketrans
# 


# Imports
# ============================================================================

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import sys
import re
import os

# Deps
# ----------------------------------------------------------------------------

from ansible.errors import AnsibleError

# Project
# ----------------------------------------------------------------------------

from qb import logging

from qb.ansible.display_handler import DisplayHandler
DisplayHandler.enable()

import qb.strings


def cap(string):
    '''just upper-case the first damn letter.
    
    >>> cap("DoSomething")
    'DoSomething'
    
    >>> cap('doSomething')
    'DoSomething'
    '''
    return string[0].upper() + string[1:]


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
    words = qb.strings.words(string)
    return words[0] + "".join(cap(s) for s in words[1:])


def cap_camel_case(string):
    '''convert a string to camel case with a leading capital.
    
    >>> cap_camel_case("git_submodule_update")
    'GitSubmoduleUpdate'
    
    >>> cap_camel_case("git-submodule-update")
    'GitSubmoduleUpdate'
    
    >>> cap_camel_case("qb.do_something")
    'QbDoSomething'
    '''
    return cap(camel_case(string))


class FilterModule(object):
    ''' some string filters '''

    def filters(self):
        return {
            'cap': cap,
            'words': qb.strings.words,
            'camel_case': camel_case,
            'cap_camel_case': cap_camel_case,
            'class_case': cap_camel_case,
            'name_to_filepath': qb.strings.name_to_filepath,
            'url_to_filepath': qb.strings.url_to_filepath,

            # Depreciated:
            'to_filepath': qb.strings.filepath,
        }


# testing - call camel_case on first cli arg and print result
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    
