#!/usr/bin/env python

from __future__ import absolute_import, division, print_function
__metaclass__ = type

from ansible.module_utils.basic import AnsibleModule

from ruamel.yaml import YAML


def apply(target, update):
    method = None
    payload = None
    kwds = {}
    for key, value in update.iteritems():
        if key[0] == '$':
            if not cmd is None:
                raise StandardError(
                    "More than one method: {}, {} in {}".format(
                        method, key[1:], target
                    )
                )
            method = key[1:]
            payload = value
        else:
            kwds[key] = value
    return getattr(sys.modules[__name__], method)(target, payload, **kwds)


def contains(target, payload, **kwds):
    present = False

    for entry in target:
        if entry == payload:
            present = True

    if present:
        return 


def main():
    yaml = YAML()

    module = AnsibleModule(
        argument_spec=dict(
            dest=dict(type='path', required=True, aliases=['path', 'file']),
            update=dict(type='dict', required=True),
        ),
        supports_check_mode=False,
    )

    params = module.params
    dest = params['dest']
    update = params['update']

    with open(dest) as f:
        parse = yaml.load(f)
    
    result = apply(parse, update)

# main

if __name__ == '__main__':
    main()