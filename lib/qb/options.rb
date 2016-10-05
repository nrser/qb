require 'optparse'

module QB
  module Options
    # small struct to hold the differnt names of the option now that including
    # makes it more complicated
    Option = Struct.new :qb_meta_name,
                        :cli_option_name,
                        :ansible_var_name,
                        :required,
                        :save,
                        :value
    
    # errors
    # ======
    
    # base for errors in the module, extends QB:Error
    class Error < QB::Error
    end
    
    # raised when an included role includes another, which we don't support
    # (for now)
    class NestedIncludeError < Error
      def initialize
        super "can't nest role includes"
      end
    end
    
    def self.include_role opts, options, include_var
      role_name = include_var['include']
      role = QB::Role.require role_name
      include_as = include_var['as'] || role.namespaceless
      
      QB.debug "including #{ role.name } as #{ include_as }"
      
      add opts, options, role, include_as
    end
    
    # add the options from a role to the OptionParser
    def self.add opts, options, role, include_as = nil
      QB.debug "adding options", "role" => role
      
      role.vars.each do |var|
        if var.key? 'include'
          # we don't support nested includes
          unless include_as.nil?
            raise NestedIncludeError.new
          end
          
          include_role opts, options, var
          
        else
          # create an option
          
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
          save = if var.key? 'save'
            !!var['save']
          else
            true
          end
          
          option = options[cli_option_name] = Option.new qb_meta_name,
                                                cli_option_name,
                                                ansible_var_name,
                                                required,
                                                save,
                                                nil
          
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
                "default --#{ cli_option_name }"
              else
                "default --no-#{ cli_option_name }"
              end
            else
              "default = #{ role.defaults[ansible_var_name] }"
            end
          end
          
          QB.debug "adding option", option: option, on_args: on_args
          
          opts.on(*on_args) do |value|
            QB.debug  "setting option",
                      option: option,
                      value: value
            
            option.value = value
          end
        end
      end # each var
    end # add 
    
    def self.parse! role, args      
      options = {}
      
      opt_parser = OptionParser.new do |opts|
        opts.banner = "qb #{ role.name } [OPTIONS] DIRECTORY"
        
        add opts, options, role
        
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