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



# Shared Contexts
# =====================================================================

shared_context "require QB::Role for path" do
  subject(:role) { QB::Role.require path }
end # QB::Role


shared_context "test role paths" do
  let(:deep_role_path) { 'qb/deep/role/test' }
  
  let(:legacy_name_role_path) { 'qb.legacy_name' }
  
  let(:mixed_name_role_path) { 'qb/mixed/name.test' }
  
  let(:not_in_path_role_rel_path) { 
    'test/roles_not_in_path/qb/not_in_path_test'
  }
end # test role paths




# Shared Examples
# =====================================================================

shared_examples "subject has attributes" do |attrs|
  it { is_expected.to have_attributes attrs }
end # attrs


shared_examples :instance do |klass, **kwds|
  it { is_expected.to be_a klass }
  
  if kwds[:attrs]
    it { is_expected.to have_attributes kwds[:attrs] }
  end
end # :instance



shared_examples "an instance of" do |klass, **kwds|
  context klass do
    include_examples :instance, klass, **kwds
  end #klass.name  
end # an instance of


shared_examples "an instance of the described class" do |**kwds|
  include_examples "an instance of", described_class, **kwds
end # an instance


shared_examples QB::Role do |**kwds|
  include_examples :instance, QB::Role, **kwds
end # QB::Role



