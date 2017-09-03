module QB
  # Write a message to `$stderr` if the `QB_DEBUG` env var exists.
  # 
  # Used throughout {QB}, as well as from {QB::AnsibleModule} instances, since
  # they connect {QB::Util::STDIO} streams created by the master QB process
  # to `$stdin`, `$stdout` and `$stderr`.
  # 
  # @param [Array] *args
  #   Values to be logged. If the first element is a String, it will become
  #   part of the 'header' line. Non-strings are dumped via `pretty_inspect`.
  # 
  # @return [Boolean]
  #   `true` if the message was written to `$stderr`.
  # 
  def self.debug *args
    return unless QB::Debug.on? && args.length > 0
    
    header = 'DEBUG'
    
    if args[0].is_a? String
      header += " " + args.shift
    end
    
    dumpObj = case args.length
    when 0
      header
    when 1
      {header => args[0]}
    else
      {header => args}
    end
    
    # $stderr.puts("DEBUG " + format(msg, values))
    $stderr.puts dumpObj.pretty_inspect
  end # .debug
  
end # module QB

# Functions to turn debug output on and off, and check state.
# 
# Debug output control is **global** at this time.
# 
# @todo
#   It would be nice to plugin in a full logging solution
#   ({NRSER::Logger} or other) at some point, and fine-grain it.
# 
module QB::Debug
  
  # See if debug output is turned on (global).
  # 
  # @return [Boolean]
  #   `true` if debug output is enabled.
  # 
  def self.on?
    !!ENV['QB_DEBUG']
  end # .on?
  
  # See if debug output is turned off (global).
  # 
  # @return [Boolean]
  #   `true` if debug output is disabled.
  # 
  def self.off?
    !on?
  end # .off?
  
  # Enable debug output (global).
  # 
  # @param [Boolean] say_hello: (true)
  #   If `true`, output a debug message after enabling.
  # 
  # @return [nil]
  # 
  def self.on! say_hello: true
    ENV['QB_DEBUG'] = 'true'
    QB.debug('ON') if say_hello
    nil
  end # .on!
  
  # Disable debug output (global).
  # 
  # @return [nil]
  # 
  def self.off!
    ENV.delete 'QB_DEBUG'
    nil
  end # .off!
  
end # module QB::Debug


