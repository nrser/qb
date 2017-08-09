module QB
  # Command line interface functionality.
  module CLI
    
    # CLI args that turn on debug output.
    DEBUG_ARGS = ['-D', '--DEBUG']
    
    
    # Set `QB_DEBUG` to "true" if any of {QB::CLI::DEBUG_ARGS} are present
    # in `args`. Removes those from `args` as well.
    # 
    # @param [Array<String>] args
    #   The command line args to operate on. **May be mutated.**
    # 
    # @return [Boolean]
    #   True if debug args were found.
    # 
    def self.set_debug! args
      if DEBUG_ARGS.any? {|arg| args.include? arg}
        ENV['QB_DEBUG'] = 'true'
        QB.debug "ON"
        DEBUG_ARGS.each {|arg| args.delete arg}
        true
      else
        false
      end
    end # .set_debug!
    
    
    # @return [String]
    def self.format_metadata
      if QB.gemspec.metadata && !QB.gemspec.metadata.empty?
        "metadata:\n" + QB.gemspec.metadata.map {|key, value|
          "  #{ key }: #{ value }"
        }.join("\n") + "\n"
      end
    end # .format_metadata
    
    
    def print_help_and_exit
      puts <<-END
version: #{ QB::VERSION }
#{ format_metadata }
syntax:

    qb ROLE [OPTIONS] DIRECTORY

use `qb ROLE -h` for role options.
  
available roles:

    END
      puts QB::Role.available
      puts
      exit 1
    end
    
    
  end # module CLI
end # module QB
