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


### Metadata File Location and Format ###

Metadata is provided via one of two file paths (relative to the role's root directory `<role_path>`):

1.  `<role_path>/meta/qb.yml`
    
    Metadata provided in static [YAML][] format. This is default method and should be used unless the metadata needs to be created dynamically on each role run (in ways not covered by the value options themselves).
    
2.  `<role_path>/meta/qb` (*executable*)
    
    Metadata provided by running an executable. The file must be marked as executable for the current system user.
    
    The executable is fed a [JSON][] encoding of the options collected form the CLI `run` command on `STDIN`.
    
    The executable should write the computed metadata to `STDOUT` in [YAML][] or [JSON][] format and exit successfully.
    
    > QB uses the [Ruby YAML library][] to parse the result, which accepts `JSON` as well.
    
    If `meta/qb` can't compute metadata, it should exit with an error status and write any error feedback to `STDERR` (though feedback might not be nicely relayed to the CLI user yet).

Right now, please don't provide both. At some point I'll handle this case, probably by raising an error, but for the moment I'm not sure how it's (not) handled.

> Role metadata is loaded by the {QB::Role#load_meta} function, which is called on demand when accessing the {QB::Role#meta} attribute.


<!-- References & Further Reading: -->

[YAML]: http://yaml.org/
[JSON]: https://www.json.org/
[Ruby YAML library]: http://ruby-doc.org/stdlib/libdoc/yaml/rdoc/YAML.html

******************************************************************************


### Conventions ###

#### `null` and Missing Metadata Values ####

**_QB treats keys set to `null` and missing keys identically._**

`null` is the same as not being there at all. I feel like this simplifies things. Departures from this behavior are considered bugs.

Generally, to tell QB *not* to do something assign `false`.

******************************************************************************


### Recognized Metadata Keys ###

This section lays out recognized keys and their acceptable values.

All keys are optional unless otherwise stated, though if present their values must be acceptable or errors will be raised when you try to run the role.


#### default_dir ####

Define a *strategy* (or list of *strategies*) to find a suitable default for
the `DIRECTORY` command line argument - which becomes the `qb_dir` variable in Ansible - when running a QB role.

> The role's `default_dir` metadata value is converted into a directory path in {QB::Role#default_dir}.

In brief, the *strategy* value can be:

1.  `null` (or missing)
    -   `DIRECTORY` arg must be provided on CLI.
2.  `false`
    -   No `DIRECTORY` arg is used and none will be accepted.
3.  `cwd`
    -   Use directory `run` command was run in.
4.  `git_root`
    -   Use the root of the Git repo working directory is a part of.
5.  `{exe: <path:string>}`
    -   Run the executable at `path` and use output.
6.  `{find_up: <rel_path:string>}`
    -   Walk up directories from current looking for `rel_path`.
7.  `{from_role: <role:string>}`
    -   Use the value from another role.
8.  `Array`
    -   Try each strategy until one works.

See {file:doc/qb_roles/metadata/default_dir.md} for strategy details and examples.


#### var_prefix ####

Declare prefix to be prepended to role CLI option names to form their Ansible variable name.

Because all variables are pretty much global in Ansible, you really want to prefix all your variables names to try and achieve uniqueness. the way i've been doing that is to prefix them with the 'namespaceless' part of the role name.

For example, if you have a role named `qb.project`, the 'namespace' would be `qb` and the 'namespaceless' part would be `project`. it has been my convention to then name the role variables `project_*`, like `project_owner`, `project_name`, etc..

`var_prefix` therefore defaults to the 'namespaceless' part of the role name, so that a call like

    qb qb.project --owner=nrser --name=blah

will pass variables

    project_owner: "nrser"
    project_name: "blah"

to the `qb.project` role.

However, this setting allows you to specify an alternative prefix. 

If this is set to `null` (or missing) the default behavior will be used.
