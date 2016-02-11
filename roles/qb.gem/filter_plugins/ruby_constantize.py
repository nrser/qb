import re
import subprocess
import pipes
from ansible import errors

# from bundler's implementation
# 
#       name.gsub(/-[_-]*(?![_-]|$)/) { "::" }.gsub(/([_-]+|(::)|^)(.|$)/) { $2.to_s + $3.upcase }
# 
# https://github.com/bundler/bundler/blob/7ae072865e3fc23d9844322dde6ad0f6906e3f2c/lib/bundler/cli/gem.rb#L29
# 
def ruby_constantize(s):
    ruby = 'puts "%s".gsub(/-[_-]*(?![_-]|$)/) { "::" }.gsub(/([_-]+|(::)|^)(.|$)/) { $2.to_s + $3.upcase }' % s
    return subprocess.check_output("/usr/bin/env ruby -e %s" % pipes.quote(ruby), shell=True).rstrip()

class FilterModule(object):
    '''ruby_constantize filter'''

    def filters(self):
        return {
            'ruby_constantize': ruby_constantize,
        }
