require 'pathname'
require 'yaml'

HERE = Pathname.new __dir__

src_path = HERE + 'src.yaml'
dump_path = HERE + 'dump.yaml'

src_str = File.read src_path
src_lines = src_str.lines

src_data = YAML.safe_load src_str

dump_str = YAML.dump src_data
dump_path.write dump_str
dump_lines = dump_str.lines


def pad int, to: 3
  sprintf "%0#{ to }d", int
end


def norm line
  line.sub /\s+\Z/, ''
end


def match_lines src_lines, dump_lines
  dump_to_src_indexes = {}
  unmatched_dump_line_indexes = []
  dump_lines.each_with_index do |dump_line, dump_index|
    src_index = src_lines.index { |src_line|
      norm( dump_line ) == norm( src_line )
    }

    if src_index
      dump_to_src_indexes[dump_index] = src_index
    else
      unmatched_dump_line_indexes << dump_index
    end
  end

  puts "Matched:"
  puts 
  dump_to_src_indexes.each do |dump_index, src_index|
    puts "dump:#{ pad dump_index } -> src:#{ pad src_index } : #{ dump_lines[dump_index] }"
  end
  puts
  puts "Unmatched:"
  puts 
  unmatched_dump_line_indexes.each do |dump_index|
    puts "dump:#{ pad dump_index }           : #{ dump_lines[dump_index] }"
  end

end

match_lines src_lines, dump_lines
