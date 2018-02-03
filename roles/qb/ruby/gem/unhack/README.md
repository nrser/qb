qb/ruby/gem/unhack role
==================

remove a gem submodule that was added with `qb hack_gem` (or otherwise) to hack on locally along side the main project, reverting to using the published version.

removes the submodule at `qb_dir` and removes the 

    gem <gem-name>, '~> 0.0', :path => <qb_dir>

line from `./Gemfile`.