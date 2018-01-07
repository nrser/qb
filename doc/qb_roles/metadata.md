QB Role Metadata
==============================================================================

QB metadata is a dictionary structure mapping string keys to mixed values that provides QB-specific role configuration.

**_A role is a QB role if (and only if) it has QB metadata._**


File Location and Format
------------------------------------------------------------------------------

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


-----------------------------------------------------------------------------
Conventions
-----------------------------------------------------------------------------

### `null` and Missing Metadata Values ###

**_QB treats keys set to `null` and missing keys identically._**

`null` is the same as not being there at all. I feel like this simplifies things. Departures from this behavior are considered bugs.

Generally, to tell QB *not* to do something assign `false`.


-----------------------------------------------------------------------------
Keys and Values
-----------------------------------------------------------------------------

This section lays out recognized keys and their acceptable values.

All keys are optional and default to `null`/`nil` unless otherwise stated, though if present their values must be acceptable or errors will be raised when you try to run the role.

******************************************************************************


### `ansible_options` ###

Type: `map`

Options to pass through to `ansible-playbook` command.

******************************************************************************


### `default_dir` ###

Type: `null | boolean | string | map | list`

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

******************************************************************************


### `default_user` ###

Type: `string`

User to [become][Ansible become] for the playbook.

<!-- References & Further Reading: -->

[Ansible become]: http://docs.ansible.com/ansible/latest/become.html

******************************************************************************


### `description` ###

Type: `string`

Pretty self-descriptive. Shown in the role's `help` output and other relevant places.

Keep it short. Add a `README.md` file to the role's root if you need to write more. I promise we'll use that somehow someday.

**Example**

>     description: Builds a gem using `gem build` command

******************************************************************************


### `mkdir` ###

Type:     `boolean`
Default:  `true`

When `true`, QB will create the `DIRECTORY` argument to `qb run ROLE DIRECTORY` *before* kicking off the Ansible playbook.

This is pretty much a legacy thing: it seemed like a really good idea at the start of everything and then turned out to not really be.

The default is `true` for said legacy reasons - there may still be roles hanging around that depend on it - but `qb/role/qb` creates `meta/qb.yml` files that set it to `false`, but I'd like to change the default to `false` when I get the time, so **please don't depend on the default value**.

******************************************************************************


### `options` ###

Type: `list`

Options to accept via the `qb run` CLI command and pass to the role as Ansible vars.

**Example**

>     options:
>     - name: example
>      description: an example of a variable.
>      required: false
>      type: boolean
>      short: e

******************************************************************************


### `requirements` ###

Type: `map`

Specify what the roles needs to work.

Work in progress... right now, only `requirements.gems.qb` does anything, and that checks that the version of QB running satisfies the version spec provided (RubyGems-style specs).

This can help you prevent annoying or confusing errors when a role fails because it's using newer features than the version trying to run it.

**Example** Make sure we're running QB `0.3.X`

>     requirements:
>       gems:
>         qb: ~> 0.3.0

******************************************************************************


### `save_options` ###

Type: `boolean`

When `true` saves options to a `.qb-options.yml` file so they can be repeated in subsequent runs.

Good idea but kinda shit feature that I want to replace with state stuff.

******************************************************************************


### `var_prefix` ###

Type: `string`

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
