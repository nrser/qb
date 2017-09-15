# Requirements
# =====================================================================

# stdlib
require 'yaml'

# deps
require 'cmds'


module QB; end
module QB::Ansible; end
module QB::Ansible::Cmds; end


# @todo document QB::Ansible::Playbook class.
class QB::Ansible::Cmds::Playbook < ::Cmds
  DEFAULT_PLAYBOOK_PATH = '.qb-playbook.yml'
  
  # Default executable to use, just uses a bare `ansible-playbook`, letting
  # shell path resolution do it's thing.
  DEFAULT_EXE = 'ansible-playbook'
  
  TEMPLATE = <<-END    
    <%= exe %>
    
    <%= cmd_options %>
    
    <% if verbose %>
      -<%= 'v' * verbose %>
    <% end %>
    
    <%= playbook_path %>
  END
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
  # Attributes
  # ======================================================================
  
  # Path to the playbook. If a `playbook:` keyword argument is provided to
  # the constructor, then this is the path it will be written to before
  # 
  # @return [String, Pathname]
  #     
  attr_reader :playbook_path
  
  
  # Whatever to use for the `ansible-playbook` executable.
  # 
  # @return [String]
  #     
  attr_reader :exe
  
  
  # Optional playbook object to write and run.
  # 
  # @return [nil]
  #   If we should expect to find the playbook already at {#playbook_path}.
  # 
  # @return [Hash]
  #   If we will be writing a YAML dump of this object to {#playbook_path}
  #   before runnning.
  #     
  attr_reader :playbook
  
  
  # Optional role options if running a role.
  # 
  # @return [nil]
  #   If we're not running a role.
  # 
  # @return [QB::Options]
  #   If we are running a role.
  #     
  attr_reader :role_options
  
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `QB::Ansible::Playbook`.
  def initialize  playbook_path: DEFAULT_PLAYBOOK_PATH,
                  playbook: nil,
                  role_options: nil,
                  exe: DEFAULT_EXE,
                  env: QB::Ansible::Env.new,
                  format: :pretty,
                  chdir: nil,
                  **other_cmds_opts
    @exe = exe.to_s
    @role_options = role_options
    @playbook = playbook
    
    # Resolve whatever path we got to an absolute.
    @playbook_path = QB::Util.resolve playbook_path
    
    super TEMPLATE,
          format: format,
          chdir: chdir,
          **other_cmds_opts
    
    # Overwrite `@env` because `super` freezes it.
    @env = env
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================  
  
  # @return [Hash<String => Object>]
  #   Hash of CLI options for `ansible-playbook` based off {#role_options}
  #   and {#playbook}.
  # 
  def cmd_options
    cmd_options = {}
    
    if role_options
      # Merge in any Ansible options collected.
      cmd_options.merge! role_options.ansible
      
      # Add tags if we have them
      if role_options.qb['tags']
        cmd_options['tags'] = role_options.qb['tags']
      end
    end
    
    # Add inventory file if we have it in QB options for the role.
    if role_options && role_options.qb['inventory']
      cmd_options['inventory-file'] = role_options.qb['inventory']
    elsif playbook && playbook[0]['hosts'] != ['localhost']
      # TODO  I'm not totally sure why this is here, but I copied it over from
      #       `//exe/qb`...? Get overridden below anyways if
      cmd_options['inventory-file'] = play['hosts']
    end
    
    cmd_options
  end # cmd_options
  
  
  # Dynamically form the keywords from instance variables.
  # 
  # @return [Hash{Symbol => Object}]
  # 
  def kwds
    {
      exe: exe,
      verbose: (role_options && role_options.qb['verbose']),
      playbook_path: playbook_path.to_s,
      cmd_options: cmd_options,
    }
  end # #kwds
  
  
  # Override so we can call `#to_h` in case `env` is {QB::Ansible::Env}.
  def env
    @env.to_h
  end
  
  
  # Stuff to do before being run, like write {#playbook} to {#path} (unless
  # {#playbook} is `nil`).
  # 
  # @return [nil]
  # 
  def before_spawn
    # Write the playbook to the path first if one was provided.
    unless playbook.nil?
      playbook_path.open('w') { |f|
        f.write YAML.dump(playbook)
      }
    end
  end # #before_write
  
  
  protected
  # ========================================================================
    
    def spawn *args, **kwds, &input_block
      before_spawn
      super *args, **kwds, &input_block
    end
    
  # end protected
  
end # class QB::Ansible::Playbook
