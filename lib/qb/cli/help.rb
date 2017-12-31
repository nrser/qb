# Requirements
# =====================================================================

# package


# Declarations
# =======================================================================

module QB; end


# Definitions
# =======================================================================

module QB::CLI 
  
  # Show the help message.
  # 
  # @todo 
  #   We should have more types of help.
  # 
  # @return [1]
  #   Error exit status - we don't want `qb ... && ...` to move on to the 
  #   second command when we end up falling back to `help`.
  # 
  def self.help args = []
    metadata = if QB.gemspec.metadata && !QB.gemspec.metadata.empty?
      "metadata:\n" + QB.gemspec.metadata.map {|key, value|
        "  #{ key }: #{ value }"
      }.join("\n")
    end
    
    puts <<-END
version: #{ QB::VERSION }

#{ metadata }

syntax:

  qb ROLE [OPTIONS] DIRECTORY

use `qb ROLE -h` for role options.

available roles:

    END
    puts QB::Role.available
    puts
    
    return 1
  end # .help
  
end # module QB::CLI


