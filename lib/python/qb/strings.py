# -*- coding: utf-8 -*-

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import re



# Constants
# ============================================================================

# Regular expression to split strings into their module namespace pieces by
# `::` (Ruby) or `.` (Python, Javascript).
# 
NAMESPACE_SPLIT_RE = re.compile(r'(?:\:\:)|\.|\#')


# Functions
# ============================================================================

def words(string):
    '''break a string into words
    
    >>> words('git_submodule_update')
    ['git', 'submodule', 'update']
    
    >>> words("qb.DoSomething")
    ['qb', 'Do', 'Something']
    
    >>> words("TestGem::SomeClass")
    ['Test', 'Gem', 'Some', 'Class']
    
    >>> words("MyAPIClass")
    ['My', 'API', 'Class']
    
    >>> words('ThisIsAName')
    ['This', 'Is', 'A', 'Name']
    
    >>> words('404Error')
    ['404', 'Error']
    
    >>> words('MyPackageV1')
    ['My', 'Package', 'V', '1']
    
    # Don't work with doctest I guess..?
    # >>> [print(_) for _ in words(u'中文')]
    # [u'中文']
    '''
    
    consumers = [
        [tag, [re.compile(pattern, re.U) for pattern in patterns]]
        for tag, patterns in 
        [
            ['break', [r'([\W\_]+)']],
            ['lower_case', [r'([a-z]+)']],
            ['capitalized', [r'([A-Z][a-z]+)']],
            ['acronym', [
                r'([A-Z]+)[A-Z][a-z]',
                r'([A-Z]+)[0-9]',
                r'([A-Z]+)\z',
            ]],
            ['number', [r'([0-9]+)']],
            ['other', [r'([^0-9a-zA-Z]+)']],
        ]
    ]
    
    def find(remaining):
        for tag, exps in consumers:
            for exp in exps:            
                # print("matching %s %s %s" % (tag, exp, remaining))
                match = exp.match(remaining)
                if match:
                    # print("matched %s! %s" % (tag, match.group(0)))
                    return [tag, exp, match]
        raise StandardError("bad string: %s" % remaining)
    
    index = 0
    results = []
    remaining = string
    
    while len(remaining) > 0:
        [tag, exp, match] = find(remaining)
        if tag != 'break':
            results.append(remaining[:match.end(1)])
        remaining = remaining[match.end(1):]
    
    return results


def snake(name):
    '''
    Turn a name into underscore-separated lower case.
    
    >>> snake('git_submodule_update')
    'git_submodule_update'
    
    >>> snake("qb.DoSomething")
    'qb_do_something'
    
    >>> snake("TestGem::SomeClass")
    'test_gem_some_class'
    
    >>> snake("MyAPIClass")
    'my_api_class'
    
    >>> snake('ThisIsAName')
    'this_is_a_name'
    
    >>> snake('404Error')
    '404_error'
    
    >>> snake('MyPackageV1')
    'my_package_v_1'
    
    '''
    return '_'.join([part.lower() for part in words(name)])


def filepath(name):
    '''
    Turn a name into a file path.

    >>> filepath('TestGem::SomeClass')
    'test_gem/some_class'
    
    >>> filepath('TestGem::SomeClass#that_method')
    'test_gem/some_class/that_method'
    
    # TODO
    # >>> filepath("TestGem::SomeClass How to do something")
    # 'test_gem/some_class/how_to_do_something'
    
    >>> filepath('qb.strings.filepath')
    'qb/strings/filepath'
    
    '''
    namespaces = NAMESPACE_SPLIT_RE.split(name)
    snaked = [snake(words_) for words_ in namespaces]
    joined = "/".join(snaked)
    return joined


# testing - call camel_case on first cli arg and print result
if __name__ == '__main__':
    import doctest
    doctest.testmod()
