
class Role
  def description
    "It's me!"
  end
  
  composing :ForOptionParser, as: :option_parser, bind: {self: :role} do
    
    def option_parser_description
      role.description.lines.map do |line|
        case line
        when ''
          # Need a space for {OptionParser} to respect it
          ' '
        when /\A\s*\-\ /
          line.sub '-', '*'
        else
          line
        end
      end
    end
    
    def option_parser_bool_args included:
      if !included && meta[:short]
      end
    end
    
    def option_parser_args
      args = if type == t.bool
        option_parser_bool_args
      else
        option_parser_non_bool_args
      end
    end
    
  end
end

Role.new.for_option_parser.description
