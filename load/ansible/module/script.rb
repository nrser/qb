
# Reinstate Bundler ENV vars if they have been moved
load ENV['QB_REBUNDLE_PATH'] if ENV['QB_REBUNDLE_PATH']

require 'qb/ansible/module'
require 'nrser/types'
require 'nrser/core_ext/exception'


# Constants
# ========================================================================

MAIN = self
NAME = File.basename( $0 ).gsub( '.', '/' ).camelize
LOGGER = NRSER::Log[ NAME ]
RAW_ARGS, ARGS_SOURCE = QB::Ansible::Module.load_args
ARG_DEFS = {}
ARGS = {}


# Global Variables
# ============================================================================

$response = QB::Ansible::Module::Response.new


# Global Methods
# ============================================================================

# Constant Readers
# ----------------------------------------------------------------------------
# 
# Just to make 'em feel familiar...
# 

def logger;     LOGGER;         end
def t;          NRSER::Types;   end
def name;       NAME;           end
def raw_args;   RAW_ARGS;       end
def arg_defs;   ARG_DEFS;       end
def args;       ARGS;           end
def response;   $response;      end


def arg name, **opts
  t.non_empty_sym.check! name
  
  prop = NRSER::Props::Prop.new \
    MAIN,
    name,
    reader: true,
    writer: false, **opts
  
  arg_defs[name] = prop
  
  args[prop.name] = if raw_args.key? prop.name
    prop.check! raw_args[prop.name]
  else
    prop.default **args
  end
  
  prop.names.each do |name|
    MAIN.send :define_method, name do
      args[prop.name]
    end
  end
end


def fail! msg, **values
  $response = response.to_failure \
    msg: msg,
    **values
  
  exit false
end


def response_sent?
  !!$response_sent
end


def send_response!
  if response_sent?
    logger.warn "Response has already been sent, ignoring..."
    return
  end
  
  # NOTE  *Need* to assign here or it disappears after the `logger.fatal`
  #       call!
  if (error = $!) && !error.is_a?( SystemExit )
    # We failed!
    
    # Log it
    logger.fatal error
    
    # Create a new response; don't want to carry whatever the current one
    # has in it back? Maybe we do? Ans'y doesn't set facts when modules fail,
    # it seems, so might not hurt...
    $response = response.to_failure \
      msg: error.to_s,
      exception: error.format
  end

  response_data = response.to_data( add_class: false ).compact

  logger.debug "Responding", response_data
  STDOUT.print JSON.pretty_generate( response_data )

  exit !response.failed
rescue SystemExit
  raise
rescue Exception => error
  logger.error "Internal QB Error: Failed to send response", error
  exit false
end


at_exit { send_response! unless response_sent? }


QB::Ansible::Module.setup_io!
