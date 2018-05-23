# Pre
# =====================================================================

# Add //lib to the Ruby load path
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)


# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------
require 'fileutils'
require 'pp'

# Deps
# -----------------------------------------------------------------------
require 'nrser/rspex'

# Project / Package
# -----------------------------------------------------------------------
require 'qb'

require 'support/ext'
require 'support/shared'


# Environment Detection
# ============================================================================

ENV['QB_IS_TEST_ENV'] = 'true'


# Paths
# ============================================================================

TEST_DIR = QB::ROOT / 'test'

TEST_ROLES_DIR = TEST_DIR / 'roles'

TEST_ROLE_TEMPLATE_DIR = TEST_ROLES_DIR / 'test_template'

TEST_PACKAGES_DIR = TEST_DIR / 'packages'

TEST_GEMS_DIR = TEST_PACKAGES_DIR / 'gems'

TEST_GEM_ROOT_PATH = TEST_GEMS_DIR / 'test_gem'

TEMP_DIR = QB::ROOT / 'tmp'

TEMP_ROLES_DIR = TEMP_DIR / 'roles'
FileUtils.mkdir_p TEMP_ROLES_DIR

TEMP_PACKAGES_DIR = TEMP_DIR / 'packages'

TEMP_GEMS_DIR = TEMP_PACKAGES_DIR / 'gems'
FileUtils.mkdir_p TEMP_GEMS_DIR

# Config
# ============================================================================

# Add the test roles dir to the roles path
QB::Role::PATH.unshift TEST_ROLES_DIR

NRSER::Log.setup! \
  dest: (TEMP_DIR / 'rspec.log'),
  application: 'qb',
  sync: true


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = TEMP_DIR / ".rspec_status"
  
  # Switch to stream commands running roles so you can see their output
  config.add_setting :stream_role_cmds,
    default: ENV.fetch( 'STREAM_ROLE_CMDS', false ).truthy?
end

# Helper Methods
# =====================================================================

# @param [String] name
#   name for the test role.
# 
def test_role name, merge = [], &block
  dest = QB::ROOT.join('tmp', 'roles', name)
  
  FileUtils.rm_r dest if dest.exist?
  FileUtils.mkdir_p dest.dirname unless dest.dirname.exist?
  FileUtils.cp_r TEST_ROLE_TEMPLATE_DIR, dest
  
  merge.each do |merge_name|
    merge_dir = TEST_ROLES_DIR.join merge_name
    
    Dir[
      merge_dir.join('**', '*.yml').to_s
    ].each do |merge_src|
      merge_dest = dest + Pathname.new(merge_src).relative_path_from(merge_dir)
      
      merge_src_obj = YAML.load Pathname.new(merge_src).read
      merge_dest_obj = YAML.load(merge_dest.read).merge merge_src_obj
      
      merge_dest.open 'w' do |f|
        f.puts YAML.dump(merge_dest_obj)
      end
    end
  end
  
  QB::Role.new dest
end
