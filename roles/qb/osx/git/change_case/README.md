qb/osx/git/change_case Role
===========================

Changes casing of a file or directory under Git control on OSX.

Due to OSX's default file system being *case insensitive* (and changing it to case-sensitive causing all sorts of problems), it's my current understanding that this requires:

1.  Changing the name in a way that is recognized by the case-insensitive file system.
    
2.  Committing that change.

3.  Changing the name to the desired name.

4.  Committing that change.

So that's what this role does.
