require_relative './base'

require 'nrser/refinements'
using NRSER


module QB; end
module QB::Action; end


# First and primary QB action: execute a role.
class QB::Action::Run < QB::Action::Base
  QB::Action.register self
  
  # Class Methods
  # =====================================================================
  
  # @return [String]
  # 
  def self.description
    "Run a QB role."
  end # .description
  
  
  
  # Attributes
  # =====================================================================
  
  attr_accessor :role
  
  
  # Args
  # =====================================================================
  
  arg :role_term, type: t.str(empty: false)
  arg :help, type: t.bool, default: false
  
  
  # Constructor
  # =====================================================================
  
  # Instantiate a new `QB::Action::Run`.
  def initialize args
    super args
    
    # begin
      @role = QB::Role.require role_term
    # rescue QB::Role::NoMatchesError => e
    #   puts "ERROR - #{ e.message }\n\n"
    #   # exits with status code 1
    #   help
    # rescue QB::Role::MultipleMatchesError => e
    #   puts "ERROR - #{ e.message }\n\n"
    #   # exit 1
    # end
    
    # Check that this version of QB is sufficient for the role
    QB.check_qb_version role
    
    # 
    @options = QB::Options.new role, args
  end # #initialize
  
  
  # Instance Methods
  # =====================================================================
  
  
  # Start running a role.
  def start
    super
    
    
  end # #start
  
  
end # class QB::Action::Run
