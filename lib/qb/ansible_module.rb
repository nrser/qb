require 'json'

module QB
  class AnsibleModule
    def self.stringify_keys hash
      hash.map {|k, v| [k.to_s, v]}.to_h
    end
    
    def initialize
      @changed = false
      @input_file = ARGV[0]
      @input = File.read @input_file
      @args = JSON.load @input
      @facts = {}
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
      print JSON.dump(self.class.stringify_keys(hash))
      exit 0
    end
    
    def fail msg
      exit_json failed: true, msg: msg
    end
  end
end # QB