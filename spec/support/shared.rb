# RSpec Shared Contexts
# =====================================================================

require 'support/shared/temp_gem'

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


shared_context :clear_temp_roles do
  before {
    # puts "CLEARING TEMP ROLES!!!!"
    FileUtils.rm_rf TEMP_ROLES_DIR if TEMP_ROLES_DIR.exist?
    FileUtils.mkdir_p TEMP_ROLES_DIR
  }
end # reset temp roles


shared_context :before_all_clear_temp_roles do
  before( :all ) {
    # puts "CLEARING TEMP ROLES!!!!"
    FileUtils.rm_rf TEMP_ROLES_DIR if TEMP_ROLES_DIR.exist?
    FileUtils.mkdir_p TEMP_ROLES_DIR
  }
end # reset temp roles


# RSpec Shared Examples
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
