require 'optparse'

module QB
  module Options
    def self.include_role 
      
    end
    
    # add the options from a role to the OptionParser
    def self.add opts, role, include_as = nil
      QB.debug "adding options for #{ role }"
      
      role.vars.each do |var|
        if var.key? 'include'
          case var['include']
          when String
            role_name = var['include']
            role = QB::Role.require role_name
            include_as = role.namespaceless
          when Hash
            role_name = var['include'].fetch 'role'
            role = QB::Role.require role_name
            include_as = var['include']['as'] || role.namespaceless
          else
            raise TypeError.new "include must be string or hash, found #{ var['include'].inspect }"
          end
          
          QB.debug "including #{ role.name } as #{ include_as }"
          
          add opts, role, include_as
          
        else
          # variable's name in meta
          qb_meta_name = var.fetch 'name'
          
          # name that will be used in QB cli
          cli_option_name = if include_as
            "#{ include_as }_#{ qb_meta_name }"
          else
            qb_meta_name
          end
          
          # name that is passed to ansible role
          ansible_var_name = "#{ role.var_prefix }_#{ qb_meta_name }"
          
          required = var['required'] || false
          
          arg_style = required ? :REQUIRED : :OPTIONAL
          
          # on_args = [arg_style]
          on_args = []
          
          if var['type'] == 'boolean'
            # don't use short names when included (for now)
            if include_as.nil? && var['short']
              on_args << "-#{ var['short'] }"
            end
            
            on_args << "--[no-]#{ cli_option_name }"
            
          else
            ruby_type = case var['type']
            when 'string'
              String
            when Hash
              if var['type'].key? 'one_of'
                klass = Class.new
                opts.accept(klass) {|value|
                  if var['type']['one_of'].include? value
                    value
                  else
                    raise ArgumentError, "argument '#{ cli_option_name }' must be " +
                      "one of: #{ var['type']['one_of'].join(', ') }"
                  end
                }
                klass
              else 
                raise ArgumentError, "bad type: #{ var['type'].inspect }"
              end
            else
              raise ArgumentError, "bad type: #{ var['type'].inspect }"
            end
            
            # don't use short names when included (for now)
            if include_as.nil? && var['short']
              on_args << "-#{ var['short'] } #{ cli_option_name.upcase }"
            end
            
            on_args << "--#{ cli_option_name }=#{ cli_option_name.upcase }"
            
            on_args << ruby_type
          end
          
          # description
          description = if var.key? 'description'
            var['description'] 
          else
            "set the #{ ansible_var_name } variable"
          end
          
          if var['type'].is_a?(Hash) && var['type'].key?('one_of')
            lb = "\n" + "\t" * 5
            description += " options:" + 
              "#{ lb }#{ var['type']['one_of'].join(lb) }"
          end
          
          on_args << description
          
          if role.defaults.key? ansible_var_name
            on_args << if var['type'] == 'boolean'
              if role.defaults[ansible_var_name]
                "default --#{ var['name'] }"
              else
                "default --no-#{ var['name'] }"
              end
            else
              "default = #{ role.defaults[ansible_var_name] }"
            end
          end
          
          QB.debug "adding option", name: cli_option_name, on_args: on_args
          
          opts.on(*on_args) do |value|
            options[var['name']] = value
          end
        end
      end # each var
    end # add 
    
    def self.parse! role, args      
      options = {}
      
      opt_parser = OptionParser.new do |opts|
        opts.banner = "qb #{ role.name } [OPTIONS] DIRECTORY"
        
        add opts, role
        
        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end
      
      opt_parser.parse! args
      
      options
    end # parse!
  end # Options
end # QB