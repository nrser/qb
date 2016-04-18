# qb #

qb is all about projects. named after everyone's favorite projects.

## meta/qb.yml ##

if this file exists in a role `qb` sees it will make that role available.

the contents of this file allow you to configure how `qb` uses the role.

### var_prefix ###

declare prefix to be added to variable names from the command line for
use in the role.

because all variables are pretty much global in ansible, you really want to prefix all your variables names to try and achieve uniqueness. the way i've been doing that is to prefix them with the 'namespaceless' part of the role name.

for example, if you have a role named `qb.project`, the 'namespace' would be `qb` and the 'namespaceless' part would be `project`. it has been my convention to then name the role variables `project_*`, like `project_owner`, `project_name`, etc..

`var_prefix` therefore defaults to the 'namespaceless' part of the role name, so that a call like

    qb qb.project --owner=nrser --name=blah

will pass variables

    project_owner: "nrser"
    project_name: "blah"

to the `qb.project` role.

however, this setting allows you to specify an alternative prefix. 

if this is set to `null` or any varient of `false` the default will be used.

### default_dir ###

every invocation of `qb` must have a directory it's targeting where it will place a `.qb-options.yml` if applicable. this directory is passed to the role as the `dir` option

this is often the project's root folder, and can sometimes be assembled from the values of other parameters.

### vars ###

TODO
