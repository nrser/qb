require 'spec_helper'

describe QB::Role do
  include_context "test role paths"
  
  describe "[names and spaces]" do
    
    describe "legacy builtin role (`.` namespaced)" do
      subject { QB::Role.require legacy_name_role_path }
      
      it_behaves_like QB::Role,
        and_is_expected: {
          to: {
            have_attributes: {
              name:           'qb.legacy_name',
              namespace:      'qb',
              namespaceless:  'legacy_name'
            }
          }
        }
    end # legacy builtin role
    
    
    describe "directory-structured role" do
      subject { QB::Role.require deep_role_path }
      
      it_behaves_like QB::Role, and_is_expected: {
        to: {
          have_attributes: {
            name:           'qb/deep/role/test',
            namespace:      'qb/deep/role',
            namespaceless:  'test',
          }
        }
      }
    end # directory-structured role
    
    
    describe "stupid mix of legacy and directory structured (pls don't use)" do
      subject { QB::Role.require mixed_name_role_path }
      
      it_behaves_like QB::Role, and_is_expected: {
        to: {
          have_attributes: {
            name:           'qb/mixed/name.test',
            namespace:      'qb/mixed/name',
            namespaceless:  'test',
          }
        }
      }
    end # stupid mix of legacy and directory structured (pls don't use)
    
    describe "role not in QB::Role::PATH" do
      subject { QB::Role.require not_in_path_role_rel_path }
      
      it_behaves_like QB::Role, and_is_expected: {
        to: {
          have_attributes: {
            name: 'not_in_path_test',
            namespace: nil,
            namespaceless: 'not_in_path_test',
          }
        }
      }
    end # role not in QB::Role::PATH
    
    
  end # names and spaces
  
end # QB::Role

