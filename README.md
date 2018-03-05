QB
==============================================================================

[![Gem Version](http://img.shields.io/gem/v/qb.svg)][gem]
[![Build Status](http://img.shields.io/travis/nrser/qb.svg)][travis]

[gem]: https://rubygems.org/gems/qb
[travis]: http://travis-ci.org/nrser/qb

QB is all about projects. Named after everyone's favorite projects.

QB works by running [Ansible][] plays. So you can think about it as "quarterback" if you happen to be from the corner of the world where that makes any sense.

You generally want to read these docs at

<http://www.rubydoc.info/gems/qb/>

where the links are more likely to work.

Or, if you're working from a local clone, by booting the [yard][] server via

    bundle exec yard server

and opening

<http://localhost:8808>


<!-- References & Further Reading: -->

[Ansible]: https://www.ansible.com/
[yard]: https://yardoc.org/


------------------------------------------------------------------------------
Quickies
------------------------------------------------------------------------------

1.  Status: **UNSTABLE (BUT GETTING BETTER)**
    
    A bit past experimental, but still actively exploring API and features. Any and every thing subject to breaking changes until we hit `1.0`. Generally trying to bump the minor version with larger changes, but not paying a huge amount of attention to it. Being used personally and in projects and organizations I work with.

2.  Compatibility: **Unix-based, specifically OSX**
    
    Developed and used on OSX/macOS, though [Travis tests][travis] tests pass on Linux as well (currently Ubuntu Trusty 14.04, see [Travis Build Env][]).
    
    I don't know of any fundamental reason it wouldn't work on other \*nixes, but you will probably have to figure it out yourself.
    
3.  Installation
    
    Head over to {file:doc/getting_started.md Getting Started}.

4.  More Info
    
    There is some semblance of an {file:doc/intro.md Introduction} available to get indignant about.


<!-- References & Further Reading: -->

[Travis Build Env]: https://docs.travis-ci.com/user/reference/overview/#Container-based

[Homebrew]: https://brew.sh/

[Ansible Installation]: http://docs.ansible.com/ansible/latest/intro_installation.html


------------------------------------------------------------------------------
Help!
------------------------------------------------------------------------------

Common Issues:

1.  `qb run` Command Issues
    1.  {file:doc/common_issues/qb_run/slow_gather_facts.md "Gathering Facts" is *really slow* (FQDN lookup problem)}
