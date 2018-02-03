# Definitions
# =======================================================================

module QB::CLI
  
  # List available roles.
  # 
  # @example
  #   
  #   qb list --user
  #   qb list -u
  #   qb list --local
  #   qb list -l
  #   qb list --system
  #   qb list -s
  #   qb list --path=:system
  #   qb list --path=./roles
  #   qb list -p ./roles
  #   qb list gem
  # 
  # @todo
  #   We should have more types of help.
  # 
  # @return [1]
  #   Error exit status - we don't want `qb ... && ...` to move on to the
  #   second command when we end up falling back to `help`.
  # 
  def self.list pattern = nil
    roles = if pattern
      QB::Role.matches pattern
    else
      QB::Role.available
    end
    
    puts roles
    puts
    
    return 0
  end # .help
  
end # module QB::CLI
