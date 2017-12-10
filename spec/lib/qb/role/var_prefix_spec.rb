require 'spec_helper'

describe QB::Role do
  describe '#var_prefix' do
    include_context "test role paths"
    include_context "reset role path"
    
    describe "legacy builtin role (`.` namespaced)" do
      subject { QB::Role.require legacy_name_role_path }
      
      describe "subject.meta" do
        subject { super().meta }
        
        it { is_expected.to include 'var_prefix' => nil}
      end # subject.meta
      
      it_behaves_like QB::Role,
        and_is_expected: {
          to: {
            have_attributes: {
              var_prefix: 'legacy_name',
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
            # var_prefix:     'deep_role_test',
          }
        }
      }
    end # directory-structured role
    
  end # #var_prefix
  
end # QB::Role
