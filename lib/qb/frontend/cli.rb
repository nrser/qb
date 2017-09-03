require 'nrser/refinements'
using NRSER

require 'nrser/refinements/types'
using NRSER::Types


module QB; end
module QB::Frontend; end


# {QB::Action} frontend for command line interfaces (bash-likes).
# 
class QB::Frontend::CLI
  
  # Constants
  # =====================================================================
  
  # CLI args that turn on debug output.
  DEBUG_ARGS  = ['-D', '--DEBUG'].freeze
  HELP_ARGS   = ['-h', '--help'].freeze
  
  # Constructor
  # =====================================================================
  
  def initialize args:
    @original_args = args
    @args = args.dup
    @help = false
    
    set_debug!
    QB.debug 'QB::Frontend::CLI initialized', args: @args
    
  end # #initialize
  
  
  # Instance Methods
  # =====================================================================
  
  # Set `QB_DEBUG` env var to `true` if any of {QB::CLI::DEBUG_ARGS} are 
  # present in {#args}. **Removes those from {#args} as well.**
  # 
  # @return [Boolean]
  #   `true` if debug args were found.
  # 
  def set_debug!
    if DEBUG_ARGS.any? { |arg| @args.include? arg }
      QB::Debug.on!
      DEBUG_ARGS.each { |arg| @args.delete arg }
      true
    else
      false
    end
  end # #set_debug!
  
  
  # @todo Document set_help! method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def set_help!
    if HELP_ARGS.any? { |arg| @args.include? arg }
      @help = true
      HELP_ARGS.each { |arg| @args.delete arg }
      true
    else
      false
    end
  end # #set_help!
  
  
  # Start (run/execute/whatever) the CLI frontend.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def start
    QB.debug "QB::Frontend::CLI starting..."
    
    # consume help option args and set `@help` if any are found.
    set_help!
    
    # If, after consuming debug and help option args, we don't have any args
    # left or we only have 'help', print top-level help and exit(1)
    if @args.empty? || @args == ['help']
      print_top_level_help_and_exit
    end
    
    # OK, find the action
    action = QB::Action.find(@args[0]) || QB::Action::Run
    
    pp action
    
  end # #start
  
  
  # TODO add an 'about' action.
  # @return [String]
  # def format_metadata
  #   if QB.gemspec.metadata && !QB.gemspec.metadata.empty?
  #     "metadata:\n" + QB.gemspec.metadata.map {|key, value|
  #       "  #{ key }: #{ value }"
  #     }.join("\n") + "\n"
  #   end
  # end # .format_metadata
  
  
  def format_cols rows, indent: nil
    # Create an array of column index => max line length of all content in that
    # column.
    max_line_lengths = []
    
    rows.each { |row|
      row.each_with_index { |col, col_index|
        # Get max line length with trailing whitespace and newline removed.
        max_line_length = col.lines.map(&:rstrip).map(&:length).max
        
        if  max_line_lengths[col_index].nil? || 
            max_line_length > max_line_lengths[col_index]
          max_line_lengths[col_index] = max_line_length
        end
      }
    }
    
    # Add spacing between cols (make cols even length with >= 2 padding)
    widths = max_line_lengths.map { |max| max + 2 + (max % 2) }
    
    # Output lines
    lines = []
    
    rows.map { |row|
      # Break each column into rstrip'd rows
      row_lines = row.map { |col| col.lines.map(&:rstrip) }
      
      # Get the max lines across all cols
      row_max_lines = row_lines.map(&:length).max
      
      # Add each line
      (0...row_max_lines).each { |line_num|
        line = []
        
        row_lines.each_with_index { |col_lines, col_index|
          line << col_lines[line_num].to_s.ljust(widths[col_index])
        }
        
        lines << line.join('')
      }
      
      # Add a newline between rows
      lines << ''
    }
    
    out = lines.join "\n"
    
    if indent
      out.indent indent
    else
      out
    end
  end # #format_cols
  
  
  def print_top_level_help_and_exit
    puts <<-END.dedent
      WELCOME TO QB!
      ==============
      
      Version: #{ QB::VERSION }
      
      Top-level syntax:
        
          qb ACTION [OPTIONS] [ARGS]
      
      Example:
      
          qb run qb.facts .
      
      Actions:
      
    END
    
    puts format_cols \
      QB::Action.registered.sort.map { |key, klass| [key, klass.description] },
      indent: 2
    
    puts <<-END.dedent
      
      For action syntax and other help:
      
          qb help ACTION 
      
    END
    
    # Exit with a failure so that `qb ... && ...` commands don't continue
    # (it really seems like it can't be what you want in that situation).
    exit 1
  end
  
end # class QB::Frontend::CLI
