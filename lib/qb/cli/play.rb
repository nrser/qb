
module QB; end

# @todo document QB::CLI module.
module QB::CLI 
  
  # Play an Ansible playbook (like `state.yml`) in the QB environment 
  # (sets up path env vars, IO streams, etc.).
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.play args
    if args.empty?
      raise "Need path to playbook in first arg."
    end
    
    path = QB::Util.resolve args[0]
    
    unless path.file?
      raise "Can't find Ansible playbook at #{ path.to_s }"
    end
    
    
    
  end # .play
  
end # module QB::CLI


