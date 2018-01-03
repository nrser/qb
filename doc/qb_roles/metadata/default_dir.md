QB Role `default_dir` Strategies
==============================================================================

Details on the acceptable values for the `default_dir` metadata key for QB roles, which I'm calling *strategies*.

-   `null` (or missing entirely) - **No strategy, DIRECTORY arg required on CLI**
    
    No strategy for figuring out a default directory.
    
    A {QB::UserInputError} will be raised by {QB::Role.default_dir}
    
-   `false` - **DIRECTORY arg not used**
    
    Role does not use a directory argument.
    
    Providing one via the command line *should* result in an error (though this is untested), and `qb_dir` will not be set in Ansible.

-   **Strategies with no parameters**
    
    Encoded as simple string values.

    -   `'cwd'` - **Current working directory**
        
        Use the working directory the `run` command was executed in.
        
        This is expected to pretty much always succeed.
        
        > **Example**
        > 
        >     default_dir: cwd
        > 

    -   `'git_root'` - **Git repo root**
        
        Use the root of the Git repo for the working directory the run command was executed in.
        
        Raises an error if that directory is not part of a Git repo.
        
        > **Example**
        > 
        >     default_dir: git_root
        > 

-   **Strategies with parameters**
    
    Encoded as directories with a single string key denoting the strategy pointing to a value holding the parameters.
    
    -   `{exe: <path:string>}` - **Run an executable**
        
        Run the executable at `path` and use the output, which should be a single string directory path (we do chomp what we get back).
        
        The exe is fed a `JSON` dump of the role options at the time via  `STDIN`, so it can dynamically determine the directory based on those if it wants.
        
        If `path` is relative, it's assumed to be relative to the *role directory*, **NOT** the working directory.
        
        Raises errors when things go wrong.
        
        > **Example** Role-relative executable
        > 
        > This will attempt to resolve the default directory by executing the `<role_path>/bin/get_default_dir` file
        > 
        >     default_dir:
        >       exe: bin/get_default_dir
        > 
        
    -   `{find_up: <rel_path:string>}` - **Find a path walking up**
        
        Walk up the directory hierarchy from the CLI working directory looking for the first place that `rel_path` exists.
        
        This is used to do things like find the `Gemfile`, nearest
        `.gitignore`, etc:
        
        > **Example** Find the nearest `Gemfile` walking up directories
        > 
        >     default_dir:
        >       find_up: Gemfile
        >
        
        > **Example** Find the nearest `.gitignore` walking up directories
        > 
        >     default_dir:
        >       find_up: .gitignore
        >
        
        `rel_path` can be deep too:
        
        > **Example** Find the nearest directory walking up for which `<dir>/dev/ref` exists
        > 
        >     default_dir:
        >       find_up: dev/ref
        >

    -   `{from_role: <role:string}` - **Use value from another role**
        
        Use the value from another QB role, which this one presumably includes.
        
        `role` can be anything you would normally use to locate a role using `qb run`, etc. (partial or full name or path).
        
        > **Example** Use the value for the `qb/ruby/bundler` role
        > 
        >     default_dir:
        >       from_role: qb/ruby/bundler
        >

-   `Array` - **Multiple strategies (fallbacks)**
    
    A list of strategies to try; first to succeed wins.
    
    > **Example** Closest `Gemfile` or Git root
    > 
    > Walk up directories looking for `Gemfile`, and if one can't be found then use the Git repo root.
    > 
    >     default_dir:
    >     -   find_up: Gemfile
    >     -   git_root
    > 
