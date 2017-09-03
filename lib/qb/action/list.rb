require_relative './base'

require 'nrser/refinements'
using NRSER


module QB; end
module QB::Action; end


# List available roles.
class QB::Action::List < QB::Action::Base
  QB::Action.register self
    
  # Class Methods
  # =====================================================================
  
  # @return [String]
  # 
  def self.description
    "List QB roles that can be run."
  end # .description
  
  
  
  # Constructor
  # =====================================================================
  
  # Instantiate a new `QB::Action::List`.
  def initialize
    
  end # #initialize
  
  
  # Instance Methods
  # =====================================================================
  
  
  # Start running a role.
  def start
    super
    
    
  end # #start
  
  
end # class QB::Action::List
