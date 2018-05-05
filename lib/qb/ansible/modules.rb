
module QB
module Ansible
# QB's built-in Ansible modules (that are written in Ruby).
# 
# Putting them here seems better than in `//library` 'cause we want to support
# composing modules, something Ansible either totally doesn't support or at
# least doesn't advertise or encourage. This means we want our Ruby modules
# in the load path, and here seemed like a decent spot.
# 
# None of these are required with `require 'qb'` - they need to be required
# individually.
# 
# I created a "super module" to run them without needed to create executables
# for each one:
# 
#     - name: >-
#         Run me some QB module...
#       
#       qb.module:
#         
#         # The module's relative path from `//lib/qb/ansible/modules`
#         #
#         # You can also use "relative" class name like `Docker::Image` or
#         # "absolute" like `::QB::Some::Other::Module` to reach classes
#         # *not* in `//lib/qb/ansible/modules`
#         #
#         name: docker/image
#         
#         # The arguments for the module
#         args:
#           path: /path/to/image/source
#           # ...
#           
# Check out `//library/qb.module.rb` for the source.
# 
# This will also let us do other "super-level" stuff like provide common
# result-value-to-fact binding or whatever (just an idea).
# 
# 
# 
module Modules; end; end; end
