# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================

using NRSER
using NRSER::Types


# Declarations
# =======================================================================

module QB::Labs; end
module QB::Labs::Atom; end


# Definitions
# =======================================================================


# @todo document QB::Atom::APM class.
class QB::Labs::Atom::APM
  
  
  # Mixins
  # ============================================================================
  
  extend SingleForwardable
  
  include SemanticLogger::Loggable
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  # @todo Document default method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def self.default
    @default ||= new
  end # .default
  
  
  def self.find_bin
    bin = ['apm-beta', 'apm'].find_map { |bin_name|
      which = Cmds.chomp 'which %s', bin_name
      
      if !which.empty? && File.executable?( which )
        which
      end
    }
    
    if bin.nil?
      raise "Could not find apm bin!"
    end
    
    bin
  end
  
  
  # Forwarding
  # ----------------------------------------------------------------------------
  
  single_delegate [:list, :installed?] => :default
  
  
  # Attributes
  # ======================================================================
  
  
  # What to use as the `apm` executable.
  # 
  # @return [String]
  #     
  attr_reader :bin
  
  
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `QB::Atom::APM`.
  def initialize bin: self.class.find_bin
    @bin = bin
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  # @todo Document list method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def list
    Cmds.out!( '%{bin} list --bare', bin: bin ).
      lines.
      each_with_object( {} ) do |line, packages|
        next if line =~ /\A\s+\z/
        
        name, version = line.chomp.split( '@', 2 )
        
        if [name, version].all? { |s| t.non_empty_str === s }
          packages[name] = version
        else
          logger.warn "Unable to parse `apm list --bare line`",
            line: line,
            name: name,
            version: version
        end
      end # each_with_object
  end # #list
  
  
  def version name:
    list[t.non_empty_str.check( name )]
  end
  
  
  # @todo Document installed? method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def installed? package_name
    list.key? t.non_empty_str.check( package_name )
  end # #installed?
  
  
  def install name:, force: false
    if current_version = self.version( name )
      logger.info "Atom package #{ name } already installed",
        version: current_version
      
      return false unless force
      
      logger.info "Forcing installation..."
    end
    
    
    
  end
  
end # class QB::Atom::APM
