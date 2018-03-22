##
# {QB::Role} methods for finding the default directory for
# running a role when one is not provided in the CLI.
# 
# Broken out from the main `//lib/qb/role.rb` file because it was starting to
# get long and unwieldy.
# 
##


# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------
require 'pathname'

# Deps
# -----------------------------------------------------------------------
require 'nrser'

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================

using NRSER


# Declarations
# =======================================================================

module QB; end


# Definitions
# =======================================================================

class QB::Role
  
  # Instance Methods
  # ======================================================================
  
  # Gets the default `qb_dir` value, raising an error if the role doesn't
  # define how to get one or there is a problem getting it.
  # 
  # It uses a "strategy" value found at the 'default_dir' key in the role's
  # QB metadata (in `<role_path>/meta/qb.yml` or returned by a
  # `<role_path>/meta/qb` executable).
  # 
  # See the {file:doc/qb_roles/metadata/default_dir.md default_dir}
  # documentation for details on the accepted strategy values.
  # 
  # @param [String | Pathname] cwd:
  #   The working directory the CLI command was run in.
  # 
  # @param [Hash<String, QB::Options::Option>] options:
  #   The role options (from {QB::Options#role_options}).
  #   
  #   TODO rename this.
  # 
  # @return [Pathname]
  #   The directory to target.
  # 
  # @raise
  #   When we can't determine a directory due to role meta settings or target
  #   system state.
  # 
  def default_dir cwd, options
    logger.debug "CALLING default_dir",
      role: self.instance_variables.assoc_to { |key|
        self.instance_variable_get key
      },
      cwd: cwd,
      options: options
    
    default_dir_for(
      strategy: self.meta['default_dir'],
      cwd: cwd,
      options: options
    ).to_pn
  end # default_dir
  
  
  protected
  # ========================================================================
    
    # Internal, possibly recursive method that actually does the work of
    # figuring out the directory value.
    # 
    # Recurs when the meta value is an array, trying each of the entries in
    # sequence, returning the first to succeed, and raising if they all fail.
    # 
    # @param [nil | false | String | Hash | Array] strategy
    #   Instruction for how to determine the directory value.
    #   
    #   See the {file:doc/qb_roles.md#default_dir default_dir} for a details
    #   on recognized values.
    # 
    # @return [return_type]
    #   @todo Document return value.
    # 
    def default_dir_for strategy:, cwd:, options:
      case strategy
      when nil
        # there is no get_dir info in meta/qb.yml, can't get the dir
        raise QB::UserInputError.new binding.erb <<-END
          No default directory for role <%= self.name %>
          
          Role <%= self.name %> does not provide a default target directory
          (used to populate the `qb_dir` Ansible variable).
          
          You must provide one via the CLI like
          
              qb run <%= self.name %> DIRECTORY
          
          or, if you are the developer of the <%= self.name %> role, set a
          non-null value for the 'default_dir' key in
          
              <%= self.meta_path %>
          
        END
      
      when false
        # this method should not get called when the strategy is `false` (an
        # entire section is skipped in exe/qb when `default_dir = false`)
        raise QB::StateError.squished <<-END
          role does not use default directory (meta/qb.yml:default_dir = false)
        END
      
      when 'git_root'
        logger.debug "returning the git root relative to cwd"
        NRSER.git_root cwd
      
      when 'cwd'
        logger.debug "returning current working directory"
        cwd
        
      when Hash
        logger.debug "qb meta option is a Hash"
        
        unless strategy.length == 1
          raise "#{ meta_path.to_s }:default_dir invalid: #{ strategy.inspect }"
        end
        
        hash_key, hash_value = strategy.first
        
        case hash_key
        when 'exe'
          exe_path = hash_value
          
          # supply the options to the exe so it can make work off those values
          # if it wants.
          exe_input_data = Hash[
            options.map {|option|
              [option.cli_option_name, option.value]
            }
          ]
          
          unless exe_path.start_with?('~') || exe_path.start_with?('/')
            exe_path = File.join(self.path, exe_path)
            debug 'exe path is relative, basing off role dir', exe_path: exe_path
          end
          
          debug "found 'exe' key, calling", exe_path: exe_path,
                                            exe_input_data: exe_input_data
          
          Cmds.chomp! exe_path do
            JSON.dump exe_input_data
          end
          
        when 'find_up'
          rel_path = hash_value
          
          unless rel_path.is_a? String
            raise "find_up relative path or glob must be string, found #{ rel_path.inspect }"
          end
          
          logger.debug "found 'find_up' strategy", rel_path: rel_path
          
          cwd.to_pn.find_up! rel_path
        
        when 'from_role'
          # Get the value from another role, presumably one this role includes
          
          default_dir_for \
            strategy: QB::Role.require( hash_value ).meta['default_dir'],
            cwd: cwd,
            options: options
          
        else
          raise QB::Role::MetadataError.new binding.erb <<-END
            Bad key <%= hash_key.inspect %> in 'default_dir' value
            
            Metadata for role <%= name %> read from
            
                <%= self.meta_path.to_s %>
            
            contains an invalid default directory strategy
            
                <%= strategy.pretty_inspect %>
            
            The key <%= hash_key.inspect %> does not correspond to a recognized
            form.
            
            Valid forms are:
            
            1.  {exe:         FILEPATH}
            2.  {file_up:     FILEPATH}
            3.  {from_role:   ROLE}
            
          END
        end
      
      when Array
        strategy.try_find do |candidate|
          default_dir_for strategy: candidate, cwd: cwd, options: options
        end
      
      else
        raise QB::Role::MetadataError.new binding.erb <<-END
          bad default_dir strategy: <%= strategy %>
        END
      end # case strategy
    end # .default_dir_for
    
  # end protected
  
end # class QB::Role
