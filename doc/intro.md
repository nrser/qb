A Rough Introduction to QB
==============================================================================

Ok, So WTF Is It?
------------------------------------------------------------------------------

QB is a wrapper around [Ansible Roles][] (Ansible's principle unit of code generalization and reuse) that provides a [command line interface][] (here-after referred to as the *CLI*, which just means you use it from the *terminal* or *console* or *shell* or whatever you call the thing you type commands into) for running roles on-the-fly.

Instead of writing an [Ansible playbook][] file along with all the necessary [configuration][Ansible configuration] you can just open up a terminal and tell it what you want to do, and QB finds the roles, sets up the paths and host, builds the playbook, and runs it.

It also provides help on which roles are available, what they do, and what arguments and options they accept, along with a mess of other features and functionality aimed to make it nicer and easier to write and run Ansible roles that manage your project state.

QB is written in Ruby and distributed as a gem. This is kinda a pain-in-the-ass because Ansible is written in Python, so they can't share a runtime, and Ruby doesn't naturally compile/package into a binary, so you end up dealing with [rbenv][] and getting all the paths pointing the the right version and all that other fuss.

But hey, Ruby just *feels good man*, and at least it has it's packaging, pathing, distribution and environment management a far-sight better together than Python (in, like, my opinion... I find RubyGems, Bundler, `Gemfile` and `rbenv` a lot less troublesome than `pip`, `virtualenv`, `requirements.txt` and the dreaded `site-packages`).


<!-- References & Further Reading: -->

[command line interface]: https://en.wikipedia.org/wiki/Command-line_interface

[Ansible Roles]: http://docs.ansible.com/ansible/latest/playbooks_reuse_roles.html

[Ansible playbook]: http://docs.ansible.com/ansible/latest/playbooks.html

[Ansible configuration]: http://docs.ansible.com/ansible/latest/intro_configuration.html

[rbenv]: https://github.com/rbenv/rbenv


-----------------------------------------------------------------------------
Why Would You Want To Do A Stupid Thing Like That?
-----------------------------------------------------------------------------

Basically, [idempotence][]. I want the human (that's you!) to say how things should be and the computer to do what needs to be done (and only what needs to be done) to make it like that.

Ansible:

1.  Has a big library of idempotent functionality (that they call [modules][Ansible Modules]) covering a lot of common system resources and states (and they're pretty well documented).
    
2.  Uses a very easy to understand execution paradigm (here's a list of stuff, go through it in order).
    
3.  Is reasonably easy to extend in simple and useful ways, like writing modules, roles, and the more common plugin types.

On the downside, Ansible:

1.  Is extremely slow to execute `localhost`-targeted playbooks (by CLI standards).
    
2.  Is difficult to extend in complex and useful ways (mostly due to the nearly-complete lack of [Python API][Ansible Python API] documentation).
    
    Trying to write vars and action plugins falls in this category for me, along with most the other "look at the source and maybe you can find something kinda like what you want and then screw around off that until it sorta works" stuff.
    
3.  Generally greets you with a old-school-PHP-esque awkwardness once you wade in past the kiddie pool, seemingly due to a similar legacy of an extremely simple system that had things *resembling* common programing features bolted on without always lining up the holes or tightening the screws.
    
    See: parametrized roles when all variables are kinda maybe global; modules without any concept of extension or composition, etc.


So, QB tries to make using all that Ansible stuff easier for your everyday tasks and work around some of the wonkiness a bit.


<!-- References & Further Reading: -->

[Idempotence]: https://en.wikipedia.org/wiki/Idempotence

[Ansible Modules]: http://docs.ansible.com/ansible/latest/list_of_all_modules.html

[Ansible Python API]: http://docs.ansible.com/ansible/latest/dev_guide/developing_api.html
