QB CLI Arguments and Options Design Notes
==============================================================================

Right now, I'm using Ruby's `optparse` or whatever it's exactly called, but the I feel like the growth of the system has been asking something more for quite some time.

There are several "layers" of options we want to accept:


`qb run`
------------------------------------------------------------------------------

1.  *Role options* (that turn into the role vars in Ansible).
    
    We want to keep this "space" as open as possible so that role creators can use the natural names for short and long options.
    
    We also want this to use the "standard" \*nix CLI-style so users feel at home with the central interface.
    
    This means we want role options to have `--name` and `-n` style options available, and preferably all of them (*almost*, we do intercept `--help`, `-h` and `-H` to display help).
    
    Hence *everything else* should be placed outside these style-spaces.
    
2.  `run` *command options*, which are currently called "QB options" in legacy of when `run` was the only command.
    
    These tell {QB::CLI.run} what to do / not do.
    
    Right now they include things like `--PRINT` and `--NO-RUN`, as well as many "pass throughs" like `-V` and `--TAGS` that are converted to *Ansible CLI options*.

3.  *Ansible CLI options* that are passed to `ansible-playbook`
    
    At the moment, you can pass these like `--ANSIBLE-...`.


(2) and (3) (and whatever else may come?) can probably share a convention, as they do now: capitalization.

I don't really like capitalization as the differentiator because it

1.  Prevents use from using the common "cap of short => false":
    
    > If boolean option `--blah` has short `-b` then `-B` means `blah` should be `false.`
    
2.  Is tiring to type for those long-form.

So I think I'd like to do something with a prefix, which will mean custom parsing (kinda knew QB would ned up there eventually, but it was nice to ride `optparse` while it lasted).


### Ideas...

`.`-namespacing seems nice, and I have seen other CLIs use it.

    # Fully namespaced
    --qb.print=cmd,playbook
    
    # and can do Ansible CLI things with it too
    --ansible.inventory=localhost
    
    # as well as Ansible config
    --ansible.config.gathering=explicit
    
    # Resolve to "closest", which would be the command?
    --.print=cmd,playbook

I think it's important to support a short form as well, which I don't see any way around getting a little weirder...

    -.p cmd,playbook # Think this is the clear winner
    -~v -~p # Gross
    -Qp # nah, bad 'cause blocks the "no space" short form
