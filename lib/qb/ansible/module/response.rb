# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Deps
# -----------------------------------------------------------------------

require 'nrser/props/mutable/instance_variables'


# Refinements
# =======================================================================

using NRSER::Types


# Definitions
# =======================================================================


# Encapsulation of data that an Ansible module responds to Ansible with.
# 
# Ansible calls this a module's "return value".
# 
# @see http://docs.ansible.com/ansible/latest/reference_appendices/common_return_values.html
# 
class QB::Ansible::Module::Response
  
  # Mixins
  # ========================================================================
  
  include NRSER::Props::Mutable::InstanceVariables
  
  
  # @!group Props
  # ==========================================================================
  
  # "Common" Values
  # --------------------------------------------------------------------------
  
  # For those modules that implement backup=no|yes when manipulating files,
  # a path to the backup file created.
  # 
  # The file must exist if provided.
  # 
  prop  :backup_file,
        type: t.file_path?
  
  
  # A boolean indicating if the task had to make changes.
  # 
  prop  :changed,
        type: t.bool,
        default: false
  
  
  # A boolean that indicates if the task was failed or not.
  # 
  prop  :failed,
        type: t.bool,
        default: false
  
  # Ansible says "Information on how the module was invoked."
  # 
  # I have no idea what that means and couldn't find anywhere it was being
  # set in a quick search of their module sources.
  # 
  prop  :invocation,
        type: t.any
  
  
  # A string with a generic message relayed to the user.
  # 
  prop  :msg,
        type: t.str?
  
  
  # A return (exit) code, if one makes sense, I guess.
  # 
  # Ansible says:
  # 
  # > Some modules execute command line utilities or are geared for executing
  # > commands directly (raw, shell, command, etc), this field contains
  # > ‘return code’ of these utilities.
  # 
  prop  :rc,
        type: t.unsigned?
  
  
  # "Internal Use" (Consumed by Ansible)
  # --------------------------------------------------------------------------
  
  # This key should contain a dictionary which will be appended to the facts
  # assigned to the host.
  # 
  # These will be directly accessible and don’t require using a registered
  # variable.
  # 
  prop  :ansible_facts,
        aliases: [ :facts ],
        type: t.hash_( keys: t.non_empty_str ),
        default: -> { HashWithIndifferentAccess.new },
        from_data: :with_indifferent_access.to_proc
  
  
  # This key can contain traceback information caused by an exception in a
  # module. It will only be displayed [to the user] on high verbosity (-vvv).
  # 
  # Unclear what the value type is, guessing string...
  # 
  prop  :exception,
        type: t.str?
  
  
  # @!attribute [rw] warnings
  #   This key contains a list of strings that will be presented to the user.
  #   
  #   @return [Array<String>]
  #     Non-empty string warning messages to return to Ansible.
  # 
  prop  :warnings,
        type: t.array( t.non_empty_str ),
        default: -> { [] }
  
  
  # @!attribute [rw] depreciations
  #   This key contains a list of dictionaries that will be presented to the
  #   user. Keys of the dictionaries are msg and version, values are string,
  #   value for the version key can be an empty string.
  #   
  #   @return [Array<{ msg: String, version: String }>]
  # 
  prop  :depreciations,
        type: t.array(
          t.shape( msg: t.non_empty_str, version: t.non_empty_str )
        ),
        default: ->{ [] }
  
  
  # @!endgroup Props # *******************************************************
  
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `QB::Ansible::Module::Response`.
  def initialize values = {}
    initialize_props values
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  
end # class QB::Ansible::Module::Response
