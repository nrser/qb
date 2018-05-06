# Restores Bundler ENV vars that were moved when spawning the Ansible process.
# 
# See `//lib/qb/util/bundler.rb` for documentation on how and why we do this.
# 

# Keep track of the ENV vars we overwrite so we can swap them back in
# later when we need to do things like shell out.
#       
$qb_replaced_env_vars = {}


ENV.each do |k, v|
  if k.start_with? 'QB_BUNDLER_ENV_'
    key = k.sub 'QB_BUNDLER_ENV_', ''
    $qb_replaced_env_vars[key] = [ENV[key], v]
    ENV[key] = v
  end
end


require 'bundler/setup'
