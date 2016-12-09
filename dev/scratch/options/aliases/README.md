want to be able to support option names having aliases. because sometimes it's hard to remember exactly what the option is called, and qb aims to make things as stupid fast and easy from the command line as possible (at the expense of more complexity in the code).

driven at the moment by wanting the qb option `-H` / `--HOSTS` to be available as `-I` / `--INVENTORY` (the ansible name for it) as well as `--HOST`, so that's what the initial example at least will focus on.
