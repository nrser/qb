CLI Design Notes
========================================================================

Motivated by the state playbook design notes.

We're now going from having one implicit command that executes roles to having at least a few distinct, explicit commands. The current roster:

**Essential**

1.  The default - run a role.
    
    The command we started with that executes a role. I want to try to keep things so this behavior stays the same - unless we match another command here, we do this.
    
    However, it should probably have a name.
    
    -   `run`
    -   `exec`
    -   `play`
    
2.  List roles we can run.
    
    This is what QB does at the moment when no args are provided. I'd like to keep that functionality as well.
    
    `list` was my first idea for a name.
    
    Is "list" really the right term? "List" often seems to list things that are present, not those that could be... which would make it a better name for the command to list the roles in the state.
    
    Maybe...
    
    -   `available`
        -   This is really long, but it does a good job explaining what it does. Could accept abbreviations... `avail`
    -   `roles`
        -   This is pretty nice.

3.  `add` - add a role or task invocation to the state playbook.
    
    Pretty sure on name for this one.
    
4.  `remove` - opposite of `add`.
    
    Pretty strait-forward concept.
    
5.  Run the state playbook.
    
    Some names I thought of over at `dev/notes/design/state.yml`, as well as additions made here:
    
    -   `sync`
    -   `play`
    -   `install`
    -   `setup`

**Nice to Have**

1.  `help`
    
    With help for the commands too.
    
2.  List the stuff in the state playbook.
    
    Maybe call this `state`?
    
    I mean, `cat state.yml` seems like it would pretty much do the trick, so this is some-what low priority.
    
3.  
