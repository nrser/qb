require 'json'

module QB
  class AnsibleModule
    @@arg_types = {}
    
    def self.stringify_keys hash
      hash.map {|k, v| [k.to_s, v]}.to_h
    end
    
    def self.arg name, type
      @@arg_types[name.to_sym] = type
    end
    
    def initialize
      @changed = false
      @input_file = ARGV[0]
      @input = File.read @input_file
      @args = JSON.load @input
      @facts = {}
      
      # if QB_STDIO_ env vars are set send stdout and stderr
      # to those sockets to print in the parent process
      
      if ENV['QB_STDIO_OUT']
        $stdout = UNIXSocket.new ENV['QB_STDIO_OUT']
      end
      
      if ENV['QB_STDIO_ERR']
        $stderr = UNIXSocket.new ENV['QB_STDIO_ERR']
      end
      
      @@arg_types.each {|key, type|
        var_name = "@#{ key.to_s }"
        
        unless instance_variable_get(var_name).nil?
          raise ArgumentError.new NRSER.squish <<-END
            an instance variable named #{ var_name } exists
            with value #{ instance_variable_get(var_name).inspect }
          END
        end
        
        instance_variable_set var_name,
                              type.check(@args.fetch(key.to_s))
      }
    end
    
    def run
      result = main
      
      case result
      when nil
        # pass
      when Hash
        @facts.merge! result
      else
        raise "result of #main should be nil or Hash, found #{ result.inspect }"
      end
      
      done
    end
    
    def changed! facts = {}
      @changed = true
      @facts.merge! facts
      done
    end
    
    def done
      exit_json changed: @changed,
                ansible_facts: self.class.stringify_keys(@facts)
    end
    
    def exit_json hash
      # print JSON response to process' actual STDOUT (instead of $stdout,
      # which may be pointing to the qb parent process)
      STDOUT.print JSON.dump(self.class.stringify_keys(hash))
      exit 0
    end
    
    def fail msg
      exit_json failed: true, msg: msg
    end
  end
end # QB