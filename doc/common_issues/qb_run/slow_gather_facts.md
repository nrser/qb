Common Issue: "Gathering Facts" is *really slow* (FQDN lookup problem)
==============================================================================

Like, 30 seconds kind of slow..!

I've encountered this when the system hostname is *not fully-qualified*, resulting in a DNS query (that seemingly times out after - you guessed it - 30 seconds) in attempt to figure out the hosts' Fully-Qualified Domain Name (FQDN).

The culprit in this case is a call to Python's `socket.getfqdn()`, which can be found when Ansible is gathering the `platform` facts at

<https://github.com/ansible/ansible/blob/v2.4.1.0-1/lib/ansible/module_utils/facts/system/platform.py#L49>

You can test if this is an issue with the following terminal command:

    time python -c 'import socket; print(socket.getfqdn())'

You want that to return really quickly, and should see something like:

    $ time python -c 'import socket; print(socket.getfqdn())'
    nrser-mbp.local

    real	0m0.394s
    user	0m0.015s
    sys	0m0.021s

If it obviously takes a long time and you see result more like

    $ time python -c 'import socket; print(socket.getfqdn())'
    nrser-mbp

    real	0m30.028s
    user	0m0.013s
    sys	0m0.008s

then it's definitely a problem and is **single-handedly slowing fact gathering to a crawl**.

The reason it's happening is because the system's `HostName` is not fully-qualified - notice the `nrser-mbp.local` output in the fast time and the `nrser-mbp` in the slow one.

The remedy is to add the `.local` to the `HostName`:

    sudo scutil --set HostName "$(scutil --get LocalHostName).local"

and you're all set!

> This assumes you get something reasonable out of `scutil --get LocalHostName`... you can of course just manually stick your hostname in there too.

If you have a specific hostname/network setup where `.local` doesn't make sense, you're of course going to have to do something more complicated, probably involving your local DNS resolution and/or network DNS, but the basic idea remains: get `socket.getfqdn()` to go fast.


Credit where credit is due:

1.  https://apple.stackexchange.com/questions/175320/why-is-my-hostname-resolution-taking-so-long
