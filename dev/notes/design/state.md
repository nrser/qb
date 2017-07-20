# State Design Notes

Basically... create a kind of `package.json` or `Gemfile` equivalent for QB roles that saves role invocations in an Ansible playbook - which I'm thinking of calling `state.yml` - that can then be run to bring the system up to sync.

It's an extension of what was started with `.qb-options.yml` and the `setup.yml` that `qb project` generates.


## Adding (Record? Save? Update?)

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

(1) seems like the way to go, at least to start.

### Auto-Add or Add Command?

Do we...

1.  Have roles automatically add to `state.yml` like they now do to `.qb-options.yml`?
    
    And roles have some meta setting to say if they're stateful or not?
    
2.  Use the `qb add ...` sort-of thing outlined above to make it explicit when you want to add stuff to the state?

It seems like (2) wins - it's easy to do and works well with the layering options discussed below.

### Append vs. Update

I'm thinking that sometimes we want to append a new role statement to the state playbook, and sometimes we want to update the one that's there (if there is one).

This behvaior seems like a property of the role, much like the `meta/main.yml:allow_duplicates` property that Ansible has.

"Update modes":

#### "Always"
    
It only ever makes sense to invoke this role once... it interacts with some global-esque state, either with respect to the entire system or the directory tree the state playbook lives in the root of.

An example would be a role that installs a single package, like `qb.yarn_setup` (though I'm not sure I ever got that role working, but the use case still applies).

It only makes sense to install `yarn` once (whether it's locally via npm or whatever or globally). It can have options for the `version` and whatever else, but if `qb add yarn_setup ...` is called with a different version, it should replace the previous role invocation... there's no reason when sync'ing to install one version then overwrite it with another some steps later.
    
#### "When"
    
This is the one I've been rolling over in my head... it's the complicated one, and I expect it to be the most common. Basically, they would have some 

I'll start with examples:

1.  Installing packages
    
    Along the lines of the "always-mode" example above, a role that wraps around a package manager (we'll prob have a way to wrap Ansible modules in roles or just add them as is or whatever, more on that later) would want to replace a previous role statement in the state playbook if the package name matched, and for the same reasons - only going to have one version of the package installed, confusing and wasteful to do two installs.
    
2.  `qb.install_gem`
    
    Is an interesting one that will require more thought - it takes a list of rubies to install for, so it's really like it's being run for each of those. Yeah, it *could* be keyed on that array, and it should work, but it could end up installing for some of them twice like that:
    
        `qb add install_gem --rubies=2.2.1,2.2.2`
        `qb add install_gem --rubies=2.2.2,2.2.3`
    
    `rubies` is different... what we really want is a merge, but that's more complexity. I'd like to avoid complexity at this stage.
    
    We could just have it replace with the last one and the user would need to provide all the rubies it needs to be installed for when adding it, which honestly seems like the way to go, which would put it in category (1).

3.  `qb.gitignore`
    
    Would be keyed on the `name` option.

**TODO** more examples?

So QB roles need a way of saying what options create the "upsert" key or whatever. Seems reasonable to define this in `meta/qb.yml:options` in each option def.

The default would probably be this mode with *all* options added, then developers could turn options that shouldn't matter off?

### "Never"

I'm not sure this one makes any sense, but it's the next logical thing after the first two. 
    
This would mean that a new role statement is *always* added to the state playbook, *even if the options are exactly the same as a statement that is already in there*.

This means that the role is obviously being used for side-effects, which is really the opposite of what this system is designed for - those should be included in the roles that need the side-effects, or a combinator role should be created to invoke them after doing some related work.

But, I really don't like prohibiting things on idealistic grounds that could be useful in practice with prudence.

Trying to think of examples... stuff like clearing a cache / deleting directory contents? Syncing time or something? Doing something temporary then putting it back?

All of these seems like they really should be encoded in the roles that they relate to or combined with them in combinator / super-roles (which we could eventually add features to help create). This seems like a bad choice for a system that focuses on idempotence and shies away from dependency and ordering.

Undecided. If this mode is omitted you could always hack around it by adding a keyed option that is a random uuid or something... God, I hate systems that necessitate those kind of hacks. I lean towards including this option and cautioning that I don't see any use case for it and if you find yourself using it please share how and why.


## Syncing (Play? Install?)

then have another command along the lines of `yarn install` that runs the playbook, syncing the state.

    qb sync
    qb play
    qb install
    
"Install" would be the term that seems best in line with existing systems (Yarn, Bundler), but doesn't totally feel right here.


## Execution Ordering and Dependencies

Since roles should be idempotent, the order of them shouldn't be a big deal. I'd like to stay away from involved dependency topography stuff for now, and want to keep the `state.yml` file easy to write/read by hand.

But... we need to order them in the state playbook somehow.

So... a basic proposal:

1.  By default, append the role statement to the end.
    
    This makes it so that state additions added in sequence get run in sequence, which seems reasonable and easy to reason about.

2.  When updating a role in the state playbook, bump it to the end of the list.
    
    Maybe provide an option to update in place if your heart so desires.


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


## Adding Tasks / Modules

We want to be able to "add" tasks (invoke modules) as well... no sense in wrapping all them up in roles (at least, not manually).

**TODO** more on this.
