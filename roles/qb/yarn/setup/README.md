qb/yarn/setup Role
========================================================================

------------------------------------------------------------------------
Examples
------------------------------------------------------------------------

1.  Installing a specific `yarn` version on macOS
    
        qb qb/yarn/setup --version=1.0.2
    
    This will create a `yarn@1.0.2` Homebrew formula if it doesn't exist.
    
    See the [Homebrew Formula Creation](#homebrew-formula-creation) section for more details.


------------------------------------------------------------------------
Homebrew Formula Creation
------------------------------------------------------------------------

Homebrew for some reason (probably many reasons, I just don't know them) doesn't really work like most package managers that allow you to specify what version you want to install... it kinda just has a current version. Since it can be important to control what version you and the rest of your team are using, we create a Homebrew formula for it (if it doesn't already exist).

The formula is created using the `yarn@M.m.p.rb.j2` template, and is added to the Homebrew tap in the `yarn_setup_brew_tap` variable, which defaults to

    {{ qb_git_user_name }}/versions

which will lead Homebrew to pull the Github repo at

    git@github.com:{{ qb_git_user_name }}/homebrew-versions.git

(or of course the `https` version of the URL, I don't know if using the SSH version is something I personally set up at some point because I use them for everything, but I find stuff tends to default to the `https` ones unless told otherwise.)

So, for myself, the tap would be

    nrser/versions

and the repo would be

    git@github.com:nrser/homebrew-versions.git

**The tap repo is not created if it doesn't already exist!**

You can override `yarn_setup_brew_tap` in Ansible or from the command line with the `-t, --brew-tap=BREW_TAP` option:

    qb qb/yarn/setup --version=1.0.2 --brew-tap=someone-else/versions


