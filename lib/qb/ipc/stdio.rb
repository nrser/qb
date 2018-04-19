# encoding: UTF-8
# frozen_string_literal: true

# Declarations
# =======================================================================

module QB::IPC; end

# Definitions
# =======================================================================

# Simple & shitty inter-process communication (IPC) system for passing
# standard-IO lines, intended and used to move them from Ansible module
# child processes up to the QB master process for display.
# 
module QB::IPC::STDIO
  
  # Get the ENV var name that will hold the socket path for a stream name -
  # `:in`, `:out` or `:err` - when passed from parent to child processes.
  # 
  # @example
  #   path_env_var_name :in
  #   # => "QB_STDIO_IN"
  # 
  # @param [Symbol] name
  # @return [String]
  # 
  def self.path_env_var_name name
    "QB_STDIO_#{ name.to_s.upcase }"
  end # .env_key
  
end # module QB::IPC::STDIO
