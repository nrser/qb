#!/usr/bin/env python2

# `bundler` Ansible/Jinja2 Filters for `qb/ruby/bundler` Role.
# 


# Imports
# ============================================================================

# Make Python 2 more Python 3-like
# from __future__ import (absolute_import, division, print_function)
# __metaclass__ = type

# from ansible.errors import AnsibleError

# Some imports you may often want:
# import sys
# improt os
# import subprocess
# import yaml
# improt json


# Functions
# ============================================================================
# 
# Suggested practice seems to be to define each filter as a top-level function
# then expose them via the `FilterModule#filters` method below.
# 

def gem_group_option( group ):
    '''
    Returns the Ruby string for the `group:` option value.
    
    :rtype: str
    
    >>> gem_group_option( 'jekyll_plugins' )
    ':jekyll_plugins'
    
    >>> gem_group_option( ['jekyll_plugins', 'blah'] )
    '[:blah, :jekyll_plugins]'
    '''
    
    if isinstance(group, list):
        return "[{}]".format(
            ", ".join( ":{}".format( s ) for s in sorted(group))
        )
    else:
        return ":{}".format( group )


'''
Map of `gem` call option names to handlers that convert their values to 
Ruby source stings
'''
gem_option_handlers = {
    'group': gem_group_option,
}


def gem_option_value( name, data ):
    '''
    Returns the Ruby source string for value of an option to a `gem` call
    in a Gemfile.
    
    Implementation just calls the function mapped to by `name` in 
    `gem_option_handlers`.
    
    :rtype: str
    
    >>> gem_option_value( 'group', 'jekyll_plugins' )
    ':jekyll_plugins'
    '''
    
    return gem_option_handlers[name]( data )


def gem_line( item ):
    '''
    Turn an `bundle_gems` item into a Gemfile line.
    
    >>> gem_line({
    ...     'key': 'github-pages',
    ...     'value': {
    ...         'state': 'present',
    ...         'group': 'jekyll_plugins',
    ...     }
    ... })
    "gem 'github-pages', group: :jekyll_plugins"
    
    >>> gem_line({
    ...     'key': 'github-pages',
    ...     'value': {
    ...         'state': 'present',
    ...     }
    ... })
    "gem 'github-pages'"
    '''
    
    line = "gem '{}'".format( item['key'] )
    
    options = {
        key: data
        for key, data
        in item['value'].items()
        if key != 'state'
    }
    
    if len( options ) > 0:
        option_values = ", ".join(
            "{name}: {value}".format(
                name = name,
                value = gem_option_value( name, options[name])
            )
            for name
            in sorted( options.keys() )
        )
        
        line = "{line}, {option_values}".format(
            line = line,
            option_values = option_values,
        )
    
    return line


# Module
# ============================================================================
# 
# How Ansible finds the filters. It looks like it gets instantiated with
# no arguments, at least most of the time, so it pretty much just serves as
# a well-known name to obtain the function references from.
# 
class FilterModule(object):
    '''
    `bundler` Ansible/Jinja2 filters for `qb/ruby/bundler` role.
    '''

    def filters(self):
        return {
            'bundle_gem_line': gem_line,
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
    