qb/yarn/setup Role
========================================================================

------------------------------------------------------------------------
Examples
------------------------------------------------------------------------

1.  Installing a specific `yarn` version on OSX
    
        qb run qb/yarn/setup --version=1.0.2
    
    Homebrew for some reason doesn't really work like most package managers that allow you to specify what version you want to install... it kinda just has a current version. Since it can be important to control what version you and the rest of your team are using, we create a Homebrew formula for it (if it doesn't already exist).
