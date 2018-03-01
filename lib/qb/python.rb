# encoding: UTF-8
# frozen_string_literal: true


# Definitions
# =======================================================================

module QB::Python
  
  # Switch python bin depending on local dev / Travis CI env
  # 
  # @todo
  #   Probably want more robust way of finding the Python we want and figuring
  #   out we're in Travis.
  # 
  # @return [String]
  # 
  def self.bin
    if File.exists? '/home/travis'
      'python'
    else
      'python2'
    end
  end
  
end # module QB::Python
