Getting Started with QB
==============================================================================

Meant to help get you up and running.

-----------------------------------------------------------------------------
Prerequisites
-----------------------------------------------------------------------------

1.  macOS (OSX)
    
    The only thing it's developed, tested and used on at this point, though I don't see any fundamental reason it won't run on \*nix.
    
    Exactly zero Windows support.
    
    I'm running `10.12.6` "Sierra" right now, and it's not tested in anything else because I'm not aware of any reasonably cheap and easy way to test on a variety of macOS versions.
    
2.  [Homebrew][]
    
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    
    Not totally necessary if you already have all the other prereqs setup or want to figure out how to do so on your own.
    
3.  Python 2 (for Ansible)
    
        brew install python2
    
    Should come with `pip2`. I haven't used anything except `2.7.X`, currently on `2.7.13`.
    
4.  [Ansible][Ansible Installation]
    
    I use the latest stable version available through `pip2`:
    
        pip2 install ansible
    
    I think we need at least `2.1.2`, and may need something higher by now. Using `2.4.1.0` right now, which you can explicitly install like:
    
        pip2 install ansible==2.4.1.0
    
    Basically have been upgrading whenever I hit bugs or try to use a feature just to find it isn't in my version, which has been... often.
    
5.  Recent Ruby
    
    QB uses refinements, so the Ruby `2.0.0` that ships on recent versions of macOS won't suffice. Currently testing against `2.3.4`.
    
    I use [rbenv][], something like:
    
        brew install rbenv
        rbenv init # and follow instructions
        rbenv install 2.3.4 # or whatever
        rbenv global 2.3.4
    
6.  Recent Node.js
    
        brew install node
    
    I think Node is only used right now for the [semver][] package, so if you don't use any of the version functionality in QB you probably don't need it?


<!-- References & Further Reading: -->

[Homebrew]: https://brew.sh/

[Ansible Installation]: http://docs.ansible.com/ansible/latest/intro_installation.html

[rbenv]: https://github.com/rbenv/rbenv

[semver]: https://www.npmjs.com/package/semver


-----------------------------------------------------------------------------
Installation
-----------------------------------------------------------------------------

It's just gem from there:

    gem install qb


-----------------------------------------------------------------------------
Usage
-----------------------------------------------------------------------------

Yeah TODO someday maybe.

For now just go read about {file:doc/qb_roles.md QB Roles}, that's the important part.
