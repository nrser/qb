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

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================

require 'nrser/refinements'
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
  # The strategy value can be:
  # 
  # -   `nil` - No strategy for figuring out a default directory. A
  #     {QB::UserInputError} will be raised.
  #     
  #     Corresponds to the `default_dir` key being missing in the role
  #     QB metadata or having a value of `null`.
  #     
  # -   `false` - Role does not use a directory argument, and this method
  #     should have never been called in the first place because 
  #     {QB::Role#has_dir_arg?} should have returned `false`.
  #     
  #     Raises a {QB::StateError}.
  # 
  # -   `'git_root'` - Use the root of the Git repo for the working directory
  #     the CLI command was executed in.
  #     
  #     Raises an error if that directory is not in a Git repo.
  # 
  # -   `'cwd'` - Use the working directory the CLI command was executed in.
  #     
  #     This is expected to pretty much always succeed.
  # 
  # -   `{'exe' => <path:String>}` - Run the executable at `path` and use the
  #     output, which should be a single string directory path (we do chomp
  #     what we get back).
  #     
  #     The exe is fed a `JSON` dump of the role options at the time via 
  #     `STDIN`, so it can dynamically determine the directory based on those 
  #     if it wants.
  #     
  #     If `path` is relative, it's assumed to be relative to the 
  #     *role directory*, **NOT** the working directory.
  #     
  #     Raises errors when things go wrong.
  #     
  # -   `{'find_up' => <rel_path:String>}` - Walk up the directory hierarchy
  #     from the CLI working directory looking for the first place that 
  #     `rel_path` exists.
  #     
  #     This is used to do things like find the `Gemfile`, nearest
  #     `.gitignore`, etc.:
  #     
  #         default_dir:
  #           find_up: Gemfile
  #         
  #         default_dir:
  #           find_up: .gitignore
  #     
  #     `rel_path` can be deep too:
  #     
  #         - find_up: dev/bin/console
  # 
  # -   `Array` - A list of strategies to try; first to succeed wins:
  #     
  #         default_dir:
  #         -   find_up: Gemfile
  #         -   git_root
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
  #   When we can't determine a directory due to role meta settings or system
  #   state.
  # 
  def default_dir cwd, options
    logger.debug "CALLING default_dir",
      role: self.instance_variables.map_values { |k, v|
        self.instance_variable_get k
      },
      cwd: cwd,
      options: options
    
    default_dir_for(
      value: self.meta['default_dir'],
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
    #   Instruction for how to determine the directory value. See notes in
    #   {QB::Role#default_dir}.
    # 
    # @return [return_type]
    #   @todo Document return value.
    # 
    def default_dir_for value:, cwd:, options:
      case value
      when nil
        # there is no get_dir info in meta/qb.yml, can't get the dir
        raise QB::UserInputError.new binding.erb <<-END
          No default directory for role <%= self.name %>
          
          Role <%= self.name %> does not provide a default target directory
          (used to populate the `qb_dir` Ansible variable).
          
          You must provide one via the CLI like
          
              qb run <%= self.name %> DIRECTORY
          
          or, if you are the developer of the <%= self.name %> role, set a 
          non-null value for the '<%= key %>' key in
          
              <%= self.meta_path %>
          
        END
      
      when false
        # this method should not get called when the value is false (an entire
        # section is skipped in exe/qb when `default_dir = false`)
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
        
        unless value.length == 1
          raise "#{ meta_path.to_s }:default_dir invalid: #{ value.inspect }"
        end
        
        hash_key, hash_value = value.first
        
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
          filename = hash_value
          
          unless filename.is_a? String
            raise "find_up filename must be string, found #{ filename.inspect }"
          end
          
          QB.debug "found 'find_up', looking for file named #{ filename }"
          
          QB::Util.find_up filename
          
        else
          raise QB::Role::MetadataError.squised <<-END
            bad key: #{ hash_key } in #{ self.meta_path.to_s }:default_dir
          END
          
        end
      
      when Array
        value.try_find do |candidate|
          default_dir_for value: candidate, cwd: cwd, options: options
        end
      
      else
        raise QB::Role::MetadataError.new binding.erb <<-END
          bad default_dir value: <%= value %>
        END
      end # case value
    end # .default_dir_for
    
  # end protected
  
end # class QB::Role
