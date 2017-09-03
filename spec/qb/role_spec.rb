require 'spec_helper'

describe QB::Role do
  include_context "test role paths"
  
  describe "names and spaces" do
    
    describe "legacy builtin role (`.` namespaced)" do
      subject { QB::Role.require legacy_name_role_path }
      
      it_behaves_like QB::Role, attrs: {
        name:           'qb.legacy_name',
        namespace:      'qb',
        namespaceless:  'legacy_name'
      }
    end # legacy builtin role
    
    
    describe "directory-structured role" do
      subject { QB::Role.require deep_role_path }
      
      it_behaves_like QB::Role, attrs: {
        name:           'qb/deep/role/test',
        namespace:      'qb/deep/role',
        namespaceless:  'test',
      }
    end # directory-structured role
    
    
    describe "stupid mix of legacy and directory structured (pls don't use)" do
      subject { QB::Role.require mixed_name_role_path }
      
      it_behaves_like QB::Role, attrs: {
        name:           'qb/mixed/name.test',
        namespace:      'qb/mixed/name',
        namespaceless:  'test',
      }
    end # stupid mix of legacy and directory structured (pls don't use)
    
  end # names and spaces
  
end # QB::Role

