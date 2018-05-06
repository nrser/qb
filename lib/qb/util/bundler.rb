module QB; end
module QB::Util; end

module QB::Util::Bundler
  
  # Are we running inside `bundler exec`?
  # 
  # @return [Boolean]
  # 
  def self.bundled?
    defined? ::Bundler
  end # .bundled?
  
  
  # Wrapper around {Bundler.with_clean_env} that copies the Bundler ENV vars
  # to other keys, allowing that Bundler ENV to be re-instated later,
  # specifically by child processes like Ansible module scripts that inherit
  # the ENV.
  # 
  # We execute Ansible commands in this context because any Ruby processes it
  # starts want the system environment, not the Bundler environment that QB
  # may be running in. In particular, Ansible's `gem` module fails if the
  # Bundler ENV vars are still in place, which totally make sense.
  # 
  # Instead, we let programs that want to boot up the possibly separate
  # environment that QB is running in (so they can require it - again,
  # Ansible module scripts, specifically those using {QB::Ansible::Module})
  # can load `//load/rebundle.rb`, which will restore the Bundler ENV vars
  # (and `require 'bundler/setup'`).
  # 
  # We make the absolute path to `//load/rebundle.rb` available in the "clean"
  # ENV as the `QB_REBUNDLE_PATH` var, so child Ruby programs can drop a
  # single line at the top of the file:
  # 
  #     load ENV['QB_REBUNDLE_PATH'] if ENV['QB_REBUNDLE_PATH']
  # 
  # and be set up to require QB files.
  # 
  # If QB is *not* running in Bundler ({#bundled?} returns `false`) then
  # this method simply calls `&block` and returns the value.
  # 
  # @param [Proc<() => RESULT>] &block
  #   Block to execute in the "clean" env.
  # 
  # @return [RESULT]
  #   Whatever `&block` returns when called.
  # 
  def self.with_clean_env &block
    # If we're not running "bundled" then just call the block and return
    return block.call unless bundled?
  
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
    
    qb_env = ENV.select { |k, v| k.start_with? 'QB_' }
    
    ::Bundler.with_clean_env do
      # Now that we're in a clean env, copy the Bundler env vars into
      # 'QB_BUNDLER_ENV_<NAME>' vars.
      dev_env.each { |k, v| ENV["QB_BUNDLER_ENV_#{ k }"] = v }
      
      # Set the path to the `//load/rebundle.rb` script in an ENV var.
      # 
      # Child Ruby processes that want to load up the environment QB was run
      # in look for this and load it if they find it, restoring the Bundler /
      # Ruby Gems ENV vars, allowing them to `require 'qb'`, etc.
      # 
      ENV['QB_REBUNDLE_PATH'] = (QB::ROOT / 'load' / 'rebundle.rb').to_s
      
      qb_env.each { |k, v| ENV[k] = v }
      
      # invoke the block
      block.call
    end # ::Bundler.with_clean_env
  end # .with_clean_env
  
  
  def self.unbundle! &block
    if $qb_replaced_env_vars.nil? || $qb_replaced_env_vars.empty?
      if block
        return block.call
      else
        return
      end
    end
    
    $qb_replaced_env_vars.each do |key, (original, replacement)|
      ENV[key] = original
    end
    
    $qb_replaced_env_vars = {}
    
    if block
      block.call.tap { rebundle! }
    end
  end
  
  
  def self.rebundle!
    return if $qb_replaced_env_vars.nil?
    
    unless $qb_replaced_env_vars.empty?
      raise "Looks like you're already unbundled: #{ $qb_replaced_env_vars }"
    end
    
    ENV.each do |k, v|
      if k.start_with? 'QB_BUNDLER_ENV_'
        key = k.sub 'QB_BUNDLER_ENV_', ''
        $qb_replaced_env_vars[key] = [ENV[key], v]
        ENV[key] = v
      end
    end
  end
  
end # module QB::Util::Bundler
