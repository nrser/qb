require 'nrser/refinements'
using NRSER

require 'nrser/refinements/types'
using NRSER::Types


module QB; end
module QB::Action; end

# Abstract base class for actions.
# 
# Actions are the API for execution in QB, designed to make executing QB clear
# and well-defined for programatic use from other libraries and the REPL with 
# frontends added to expose functionality over protocols.
# 
# I'm going to start by implementing a CLI frontend, with future plans to add
# HTTP and other useful interfaces.
# 
class QB::Action::Base < NRSER::Meta::Props::Base
  
  # Class Methods
  # =====================================================================
  
  # The string used to invoke the action in frontends. Must be unique across
  # all registered actions.
  # 
  # @return [String]
  # 
  def self.key
    self.name.split('::').last.downcase
  end # .key
  
  
  # Props
  # =====================================================================
  
  prop :debug, type: t.bool, default: false
  
  
  # Constructor
  # =====================================================================
  
  # Instantiate a new {QB::Action::Base}.
  def initialize **values
    super **values
    
    QB.set_debug! debug
  end # #initialize
  
  
  # Instance Methods
  # =====================================================================
  
  # Start the action (run/execute it).
  # 
  # 
  def start
    # method body
  end # #start
  
end # class QB::Action::Base

