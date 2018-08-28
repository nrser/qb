##############################################################################
# Comment-preserving YAML manipulation tool
# ============================================================================
# 
# Based around the [ruamel.yaml][] Python package, which - horribly 
# depressingly - seems to be the *only* open software available able to 
# preserve structure when modifying YAML files, which we *really* want...
# 
# [ruamel.yaml]: https://yaml.readthedocs.io/en/latest/
# 
# We've got a lot of YAML around, and it just *suuuucks* to not be able to 
# manipulate it with machines without destroying the human structure of it.
# 
# So here's to hope this works at least sorta well...
# 
##############################################################################

# Be Python-3-y
from __future__ import absolute_import, division, print_function
__metaclass__ = type

# The jewels
from ruamel.yaml import YAML


class YamlMan:

    def __init__(path=None, string=None):
        self.path = path

        if self.path is not None:
            if string is not None:
                raise 

            self.string 
    
# class YamlMan
