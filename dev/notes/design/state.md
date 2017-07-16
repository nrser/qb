# State Design Notes

Basically... create a kind of `package.json` or `Gemfile` equivalent for QB roles that saves role invocations in an Ansible playbook - which I'm thinking of calling `state.yml` - that can then be run to bring the system up to sync.

It's an extension of what was started with `.qb-options.yml` and the `setup.yml` that `qb project` generates.


## Adding

I want to be able to run `qb` commands and have them saved so that they become a permanent part of the system or project's state, equivalent to `yarn add ...`.

    qb add ref_repo --owner=beiarea --name=www-rails --version=rethink

I'm thinking you can provide a file path to add to

    qb add --PATH=./dev/state.yml ...

or...

1.  Assume the current dir?
    -   Prob simplest to do and understand.
2.  Walk up until we find...
    1.  Git root?
    2.  A `state.yml`?


## Syncing

then have another command along the lines of `yarn install` that runs the playbook, syncing the state.

    qb sync


## Execution Ordering and Dependencies

Since roles should be idempotent, the order of them shouldn't be a big deal. I'd like to stay away from involved dependency topography stuff for now, and want to keep the `state.yml` file easy to write/read by hand.


## Installing Role Dependencies

The other component that it needs is functionality to fetch and "install" missing roles before a run. It always bothered me that Ansible required two commands to install and run.


## Layering

Plan on layered functionality, where there can be states for the system, users, and projects / directories. Want to have up-front and first class support for sub-modules / sub-projects, something I feel is lacking in many environment / dependency management solutions.

Provide flags for user and global?

    qb add --USER homebrew --name=git-lfs
    qb add --SYSTEM pip --name=docker-compose

It would be nice to have roles that understand this layering and can setup their state with respect to it if possible... so dir-local gem/pip installs use `Gemfile`/Bunlder / `requirements.txt`/virtualenv to install that stuff locally... though maybe this is logically a different option :/


## Role Versioning

I've given some thought to role versioning and dependencies, but haven't arrived at much... it might just be version-less at very first, though that was one of the things that most irked me about Ansible Galaxy.
