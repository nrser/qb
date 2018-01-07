QB Roles
==============================================================================

QB roles are [Ansible roles][] that can be run via `qb run`. An Ansible role is a QB role if it has a [QB Metadata](#QB_Metadata) file - `meta/qb.yml` or `meta/qb`.


<!-- References & Further Reading: -->

[Ansible Roles]: http://docs.ansible.com/ansible/latest/playbooks_reuse_roles.html


------------------------------------------------------------------------------
Creating QB Roles
------------------------------------------------------------------------------

The easiest way to create QB roles is to use QB's `qb/role/qb` role (say *that* five times fast!):

    qb run qb/role/qb DIRECTORY [OPTIONS]

Since `run` is the default QB CLI command and role names are inferred from partial matches whenever possible, this is commonly shortened to:

    qb role/qb DIRECTORY [OPTIONS]

Which will work unless your roles path contains other roles with 'role/qb' in their name.

This will generate a `DIRECTORY/meta/qb.yml` file with common keys and values for you to start from, as well as some notes and links.


> **Example**
>
> To create a new role named `me/my_new_role` at `./roles/me/my_new_role` run
>
>     qb role/qb ./roles/me/my_new_role
>


As always, you can check out the `qb/role/qb` options via

    qb role/qb -h


------------------------------------------------------------------------------
QB Metadata
------------------------------------------------------------------------------

QB metadata is a dictionary structure mapping string keys to mixed values that provides QB-specific role configuration.

**_A role is a QB role if (and only if) it has QB metadata._**

See {file:doc/qb_roles/metadata.md QB Role Metadata} for details.
