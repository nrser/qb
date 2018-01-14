#!/usr/bin/env python2
##############################################################################
# `dependency` Ansible/Jinja2 filters for `qb/ruby/dependency` role.
##############################################################################


# Imports
# ============================================================================

# Make Python 2 more Python 3-like
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.errors import AnsibleError

# Some imports you may often want:
# import sys
# improt os
# import subprocess
# import yaml
# improt json


# Utilities
# ============================================================================

def kwd_args(f):
    '''
    Decorator to convert a single dict arg to keyword args.
    
    Allows usage of filter with keyword args as "subject" or whatever you
    call it:
    
        {
            'owner': 'beiarea',
            'name': 'www-rails_web',
            'tag': '0.1.2'
        } | to_image_id
        
    '''
    def new_f(*args, **kwds):
        if len(args) == 1 and isinstance(args[0], dict):
            return f(**args[0])
        else:
            return f(*args, **kwds)
    
    return new_f


def quote(string):
    '''
    A dumb and bad sinlge quoert that relies on the argument not having any
    single quotes in it.
    
    :param string: str String to quote
    :rtype: str
    '''
    return "'{}'".format(string)


def gemspec_dep_call(dev):
    '''
    Get the correct 'spec.add_dependency' or 'spec.add_development_dependency'
    depending on `dev`.
    
    :param dev: bool
    :rtype: str
    '''
    
    if dev:
        return 'spec.add_development_dependency'
    else:
        return 'spec.add_dependency'


# Filter Functions
# ============================================================================
# 
# Suggested practice seems to be to define each filter as a top-level function
# then expose them via the `FilterModule#filters` method below.
# 

def gemspec_dep_line(name, version = None, dev = False, indent = '  '):
    '''
    Generate a dependency line for a `.gemspec` file.
    
    :param name: The gem name
    :type name: str
    
    :param version: The optional version spec(s)
    :type version: None | str | list<str>
    
    :param dev: If the dependency is development or not
    :type dev: bool
    
    :return: The dependency line for the `.gemspec` file.
    :rtype: str
    
    >>> gemspec_dep_line(name = 'yard')
    "  spec.add_dependency 'yard'"
    
    >>> gemspec_dep_line(
    ...     name = 'yard',
    ...     version = '~> 0.9.12',
    ... )
    "  spec.add_dependency 'yard', '~> 0.9.12'"
    
    >>> gemspec_dep_line(
    ...     name = 'yard',
    ...     version = '~> 0.9.12',
    ...     dev = True,
    ... )
    "  spec.add_development_dependency 'yard', '~> 0.9.12'"
    
    >>> gemspec_dep_line(
    ...     name = 'bundler',
    ...     version = ['~> 1.16', '>= 1.16.1'],
    ...     dev = True,
    ... )
    "  spec.add_development_dependency 'bundler', '~> 1.16', '>= 1.16.1'"
    '''
    
    call = gemspec_dep_call(dev)
    args = [quote(name)]
    
    if not version is None:
        if isinstance(version, list):
            for condition in version:
                args.append(
                    quote(condition)
                )
        else:
            args.append(quote(version))
        
    return "{}{} {}".format(indent, call, ", ".join(args))


def gemspec_dep_re_str(name, version = None, dev = False):
    '''
    Generate a regex string for Ansible's `lineinfile` module to match
    a dependency line for a `.gemspec` file.
    
    Params
    
    :rtype: str
    
    Does not doctest well due to backslashness.
    '''
    
    call = gemspec_dep_call(dev)
    
    return "^\\s+{call}\s+[\\'\\\"]{name}[\\'\\\"]".format(
        call = call,
        name = name,
    )


def gemspec_dep_insert_after(name, version = None, dev = False):
    '''
    Generate a regex string for Ansible's `lineinfile` module to match
    the last `spec.add_dependency` or `spec.add_development_dependency`,
    depending on `dev`.
    
    Does not doctest well due to backslashness.
    
    :rtype: str
    '''
    
    call = gemspec_dep_call(dev)
    
    return "^\\s+{call}".format(call = call)



# Module
# ============================================================================
# 
# How Ansible finds the filters. It looks like it gets instantiated with
# no arguments, at least most of the time, so it pretty much just serves as
# a well-known name to obtain the function references from.
# 
class FilterModule(object):
    '''
    Ansible/Jinja2 filters for `qb/ruby/dependency` role.
    '''

    def filters(self):
        return {
            'to_gemspec_dep_line':          kwd_args(gemspec_dep_line),
            'to_gemspec_dep_re_str':        kwd_args(gemspec_dep_re_str),
            'to_gemspec_dep_insert_after':  kwd_args(gemspec_dep_insert_after),
        }
    # filters()
# FilterModule


# Testing
# ============================================================================
# 
# This is not standard Ansible-ness - they use `unittest.TestCase` in separate
# files - but `doctest` seemed like a really easy way to add and run tests
# for these typically simple functions.
# 
if __name__ == '__main__':
    import doctest
    doctest.testmod()
    
