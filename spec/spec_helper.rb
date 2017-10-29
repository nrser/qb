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



# Paths
# =====================================================================

TEST_ROLES_DIR = QB::ROOT.join 'test', 'roles'

TEST_ROLE_TEMPLATE_DIR = TEST_ROLES_DIR.join 'test_template'

TEST_PACKAGES_DIR = QB::ROOT / 'test' / 'packages'

TEST_GEM_ROOT_PATH = TEST_PACKAGES_DIR / 'gems' / 'test_gem'


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


# Shared Contexts
# =====================================================================

shared_context "require QB::Role for path" do
  subject(:role) { QB::Role.require path }
end # QB::Role


shared_context "test role paths" do
  let(:deep_role_path) { 'qb/deep/role/test' }
  
  let(:legacy_name_role_path) { 'qb.legacy_name' }
  
  let(:mixed_name_role_path) { 'qb/mixed/name.test' }
  
  let(:roles_not_in_path_dir) {
    QB::ROOT.join('test/roles_not_in_path').to_s
  }
  
  let(:not_in_path_role_name) { 'qb/not_in_path_test' }
  
  let(:not_in_path_role_rel_path) { 
    'test/roles_not_in_path/qb/not_in_path_test'
  }
end # test role paths

shared_context "reset role path" do
  before {
    QB::Role.reset_path!
    QB::Role::PATH.unshift TEST_ROLES_DIR
  }
  
  after {
    QB::Role.reset_path!
    QB::Role::PATH.unshift TEST_ROLES_DIR
  }
end # reset role path


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
