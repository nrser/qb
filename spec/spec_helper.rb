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

require 'support/rspec_ext'



# Paths
# =====================================================================

TEST_DIR = QB::ROOT / 'test'

TEST_ROLES_DIR = TEST_DIR / 'roles'

TEST_ROLE_TEMPLATE_DIR = TEST_ROLES_DIR / 'test_template'

TEST_PACKAGES_DIR = TEST_DIR / 'packages'

TEST_GEM_ROOT_PATH = TEST_PACKAGES_DIR / 'gems' / 'test_gem'

TEMP_DIR = QB::ROOT / 'tmp'

TEMP_ROLES_DIR = TEMP_DIR / 'roles'

# Config
# =====================================================================

# Add the test roles dir to the roles path
QB::Role::PATH.unshift TEST_ROLES_DIR


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


require 'support/shared_contexts'


# Shared Examples
# =====================================================================

shared_examples QB::Role do |**expectations|
  include_examples "expect subject",
    { to: { be_a: QB::Role } },
    *expectations.values
end # QB::Role


shared_examples "QB::Role::PATH" do |**expectations|
  subject { QB::Role::PATH }
  
  include_examples "expect subject",
    { to: { be_a: Array } },
    *expectations.values
end # QB::Role::PATH


shared_examples QB::Package::Version do |**expectations|
  include_examples "expect subject",
    { to: { be_a: QB::Package::Version } },
    *expectations.values
end # QB::Package::Version


shared_examples QB::Path do |**expectations|
  include_examples "expect subject",
    { to: { be_a: QB::Path } },
    *expectations.values
end # QB::Path


shared_examples QB::Repo::Git do |**expectations|
  include_examples "expect subject",
    { to: { be_a: QB::Repo::Git } },
    *expectations.values
end # QB::Repo::Git


shared_examples QB::Repo::Git::User do |**expectations|
  include_examples "expect subject",
    { to: { be_a: QB::Repo::Git::User } },
    *expectations.values
end # QB::Repo::Git::User
