module QB
  class Options
    class Option
      EXAMPLES_KEYS = ['examples', 'example']
      
      # the role that this option is for
      # attr_reader :role
      
      # the entry from the qb metadata for this option
      attr_reader :meta
      
      # array of strings representing how this option was included
      # empty for top-level options
      attr_reader :include_path
      
      # the name of the option in the qb metadata, equal to #meta['name']
      attr_reader :meta_name
      
      # the name that this option will be available in the cli as
      attr_reader :cli_name
      
      # the name that the value will be passed to ansible as
      attr_reader :var_name
      
      # the value of the option, or `nil` if we never assign one
      attr_accessor :value
      
      def initialize role, meta, include_path
        # @role = WeakRef.new role
        @meta = meta
        @include_path = include_path
        
        @meta_name = meta.fetch 'name'
        
        @cli_name = if @include_path.empty?
          Options.cli_ize_name @meta_name
        else
          Options.cli_ize_name "#{ @include_path.join('-') }-#{ @meta_name }"
        end
        
        @var_name = if role.var_prefix
          Options.var_ize_name "#{ role.var_prefix }_#{ @meta_name }"
        else
          Options.var_ize_name @meta_name
        end
        
        @value = nil
      end
      
      # if the option is required in the cli
      def required?
        !!meta_or(['required', 'require'], false)
      end
      
      # if we should save the option value in .qb-options.yml
      def save?
        !!meta_or('save', true)
      end
      
      def description
        value = meta_or 'description',
          "set the #{ @var_name } role variable"
        
        line_break = "\n" + "\t" * 5
          
        if @meta['type'].is_a?(Hash) && @meta['type'].key?('one_of')
          value += " options:" + 
            "#{ line_break }#{ @meta['type']['one_of'].join(line_break) }"
        end
        
        value
      end
      
      def boolean?
        (
          meta['type'].is_a?(String) &&
          ['boolean', 'bool'].include?(meta['type'].downcase)
        )
      end
      
      def usage
        if boolean?
          "--[no-]#{ cli_name }"
        else
          "--#{ cli_name }=#{ meta_name.upcase }"
        end
      end
      
      # test if the option has any examples.
      # 
      # @return [Boolean]
      # 
      def has_examples?
        EXAMPLES_KEYS.any? {|key| meta.key? key}
      end
      
      # get an array of examples for the option. returns `[]` if no examples
      # are defined.
      # 
      # @return [Array<String>]
      # 
      def examples
        value = meta_or EXAMPLES_KEYS, []
        
        if value.is_a? String then [value] else value end
      end
      
      private
      
      # get the value at the first found of the keys or the default.
      # 
      # `nil` (`null` in yaml files) are treated like they're not there at
      # all. you need to use `false` if you want to tell QB not to do something.
      # 
      def meta_or keys, default
        keys = [keys] if keys.is_a? String
        keys.each do |key|
          if meta.key?(key) && !meta[key].nil?
            return meta[key]
          end
        end
        default
      end
      
    end # Option
  end # Options
end # QB