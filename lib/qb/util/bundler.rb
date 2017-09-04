module QB; end
module QB::Util; end

module QB::Util::Bundler 
  # needed for to clean the env if using bundler (like in dev).
  # 
  # this is because the ansible gem module doesn't work right with the bundler
  # env vars set, so we need to remove them, but when running in dev we want
  # modules written in ruby like nrser.state_mate's `state` script to have
  # access to them so it can fire up bundler and get the right libraries.
  # 
  # to accomplish this, we detect Bundler, and when it's present we copy the
  # bundler-related env vars (which i found by looking at 
  # https://github.com/bundler/bundler/blob/master/lib/bundler.rb#L257)
  # into a hash to pass around the env sanitization, then copy them into
  # corresponding 'QB_DEV_ENV_<NAME>' vars that modules can restore.
  # 
  # we also set a 'QB_DEV_ENV=true' env var for modules to easily detect that
  # we're running in dev and restore the variables.
  # 
  def self.with_clean_env &block
    if defined? ::Bundler
      # copy the Bundler env vars into a hash
      dev_env = ENV.select {|k, v|
        k.start_with?("BUNDLE_") ||
        [
          'GEM_HOME',
          'GEM_PATH',
          'MANPATH',
          'RUBYOPT',
          'RUBYLIB',
        ].include?(k)
      }
      
      qb_env = ENV.select {|k, v| k.start_with? 'QB_'}
      
      ::Bundler.with_clean_env do
        # now that we're in a clean env, copy the Bundler env vars into 
        # 'QB_DEV_ENV_<NAME>' vars.
        dev_env.each {|k, v| ENV["QB_DEV_ENV_#{ k }"] = v}
        
        # set the flag that will be used by modules to know to restore the 
        # variables
        ENV['QB_DEV_ENV'] = 'true'
        
        qb_env.each {|k, v| ENV[k] = v}
        
        # invoke the block
        block.call
      end
    else
      # bundler isn't loaded, so no env var silliness to deal with 
      block.call
    end
  end # .with_clean_env
end # module QB::Util::Bundler
