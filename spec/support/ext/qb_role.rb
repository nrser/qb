# Declarations
# =======================================================================

module Support; end
module Support::Ext; end


# Definitions
# =======================================================================

# RSpec extensions mixed in to {Support::Ext::ExampleGroup#describe_qb_role}
# descendants (identified by `type: :qb_role` metadata).
# 
module Support::Ext::QBRole
  
  # Mixin for methods that will be available in example groups (inside 
  # `define`/`context` but not in the examples themselves).
  # 
  module ExampleGroup
    # None yet!
  end # module ExampleGroup
  
  
  # Mixin for methods that will be available in examples themselves
  # (inside `it`, `before`, etc.)
  # 
  # All the QB Role stuff is here because it's stuff we need in `it` blocks,
  # `before` blocks, etc.
  # 
  # You can override any of these by defining methods in the example group
  # blocks:
  # 
  #     describe_qb_role 'qb/some/role' do
  #       
  #       # Override to provide CLI options to `qb run ...`
  #       def qb_role_opts
  #         { class: 'TestGem::SomeClass' }
  #       end
  #     
  #     end
  # 
  module Example
    
    # Template that will be used for the command.
    # 
    # @return [String]
    # 
    def cmd_template
      '<%= bin %> run <%= name %> <%= dir %> <%= opts %>'
    end
    
    
    # Directory to change into when running the command.
    # 
    # Defaults to {QB::ROOT}.
    # 
    # @return [String | Pathname]
    # 
    def cmd_chdir
      QB::ROOT
    end
    
    
    # Build the {Cmds} instance using {#cmd_template} and {#cmd_chdir}.
    # 
    # Prob won't need to use this directly.
    # 
    # @return [Cmds]
    # 
    def cmd
      Cmds.new cmd_template, chdir: cmd_chdir
    end
    
    
    # The positional arguments to be passed to {Cmds#stream}, {Cmds#capture},
    # etc. inside {#run_cmd!}.
    # 
    # Default template doesn't use positional args, but if you override it with
    # one that does, you can provide them here.
    # 
    # @return [Array]
    # 
    def cmd_args
      []
    end
    
    
    # The symbolic keyword arguments to be passed to {Cmds#stream}, 
    # {Cmds#capture}, etc. inside {#run_cmd!}.
    # 
    # @return [Hash<Symbol, Object>]
    # 
    def cmd_kwds
      {
        bin: ( QB::ROOT / 'bin' / 'qb' ),
        name: described_qb_role_name,
        dir: qb_role_dir,
        opts: qb_role_opts,
      }
    end
    
    
    # The method on the {Cmds} instance from {#cmd} to call when running.
    # 
    # @return [Symbol]
    #   Right now we support `:stream` and `:capture` (as well as their `!`
    #   variants).
    # 
    def cmd_method
      if RSpec.configuration.stream_role_cmds?
        :stream
      else
        :capture
      end
    end
    
    
    # Actually run the command, setting the `@exit_status` instance variable
    # and `@result` to the {Cmds::Result} if {#cmd_method} returned `:capture`.
    # 
    # @return [nil]
    # 
    def run_cmd!
      return_value = cmd.send cmd_method, *cmd_args, **cmd_kwds
      
      case return_value
      when Fixnum
        @exit_status = return_value
      when Cmds::Result
        @result = return_value
        @exit_status = @result.status
      else
        raise "No good!? #{ return_value.inspect }"
      end
      
      nil
    end
    
    
    # The `DIRECTORY` CLI argument to provide to `qb run ...` (`qb_dir` var
    # in Ansible).
    # 
    # @return [nil | String]
    #   Defaults to `nil`.
    # 
    def qb_role_dir
      nil
    end
    
    
    # CLI options sent to `qb run ...`.
    # 
    # @return [Hash]
    # 
    def qb_role_opts
      {}
    end

    
  end # module Example
  
end # module Support::Ext::Type::QBRole
