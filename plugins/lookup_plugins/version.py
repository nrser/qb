from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.errors import AnsibleError, AnsibleParserError
from ansible.plugins.lookup import LookupBase

try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()


class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        ret = []
        
        display.debug("Excuting `version` lookup plugin...")
        
        display.debug("  terms: %s" % terms)
        display.debug("  variables: %s" % variables)
        display.debug("  kwargs: %s" % kwargs)
        
        raise AnsibleError("HERE!")
