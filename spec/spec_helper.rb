$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'qb'
require 'fileutils'
require 'pp'

TEST_ROLES_DIR = QB::ROOT.join 'test', 'roles'

QB::Role::PATH.unshift TEST_ROLES_DIR

TEST_ROLE_TEMPLATE_DIR = TEST_ROLES_DIR.join 'test_template'

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

# Merge "expectation" hashes by appending all clauses for each state.
def merge_expectations *expectations
  Hash.new { |result, state|
    result[state] = []
  }.tap { |result| 
    expectations.each { |ex|
      ex.each { |state, clauses|
        result[state] += clauses.to_a
      }
    }
  }
end



# Subject Helpers
# =====================================================================


# @todo Document refine_subject method.
# 
# @param [type] arg_name
#   @todo Add name param description.
# 
# @return [return_type]
#   @todo Document return value.
# 
def refine_subject method_name, *args
  subject {
    super_subject = super()
    new_subject = super_subject.send method_name, *args
    # raise({super_subject: super_subject, new_subject: new_subject}.inspect)
    new_subject
  }
end # #refine_subject


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

shared_examples "is expected" do |expectations|
  expectations.each { |state, specs|
    specs.each { |verb, noun|
      it {
        # like: is_expected.to(include(noun))
        is_expected.send state, self.send(verb, noun)
      }
    }
  }
end # is expected


shared_examples "expect subject" do |expectations|
  expectations.each { |state, specs|
    specs.each { |verb, noun|
      it {
        # like: is_expected.to(include(noun))
        is_expected.send state, self.send(verb, noun)
      }
    }
  }
end # is expected


shared_examples QB::Role do |**expectations|
  include_examples "is expected", merge_expectations(
    { to: { be_a: QB::Role } },
    *expectations.values,
  )
end # QB::Role


shared_examples "QB::Role::PATH" do |**expectations|
  subject { QB::Role::PATH }
  
  include_examples "is expected", merge_expectations(
    { to: { be_a: Array } },
    *expectations.values,
  )
end # QB::Role::PATH


shared_examples QB::Package::Version do |**expectations|
  include_examples "is expected", merge_expectations(
    { to: { be_a: QB::Package::Version } },
    *expectations.values,
  )
end # QB::Package::Version


shared_examples QB::Path do |**expectations|
  include_examples "is expected", merge_expectations(
    { to: { be_a: QB::Path } },
    *expectations.values,
  )
end # QB::Path


shared_examples QB::Repo::Git do |**expectations|
  include_examples "is expected", merge_expectations(
    { to: { be_a: QB::Repo::Git } },
    *expectations.values,
  )
end # QB::Repo::Git


shared_examples QB::Repo::Git::User do |**expectations|
  include_examples "is expected", merge_expectations(
    { to: { be_a: QB::Repo::Git::User } },
    *expectations.values,
  )
end # QB::Repo::Git::User


