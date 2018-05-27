`//plugins/lookup` - QB's Ansible Lookup Plugins
==============================================================================

"Lookup" plugins that run on the *host* machine - *not the target* - though QB pretty much just targets the host and fudges the difference where it makes things more convenient / reasonable / possible (which is probably not good, but it tremendously simplifies a lot of things and works).


Ansible Docs
------------------------------------------------------------------------------

> Please check the Ansible version versus docs version.

https://docs.ansible.com/ansible/2.5/plugins/lookup.html


Notes
------------------------------------------------------------------------------

Lookup plugin files seem to need to be named *exactly* after the lookup name!

So the `every` lookup needs to be in a file named `every.py`, **not** `every_lookup.py` - or anything else.
