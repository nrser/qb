require 'spec_helper'


describe QB::Role do
  
  describe "[roles path]" do
    include_context "test role paths"
    include_context "reset role path"
    
    describe 'QB::Role::PATH' do
      subject { QB::Role::PATH }
      it { is_expected.not_to include roles_not_in_path_dir }
    end # QB::Role::PATH
    
    it "can't find qb/not_in_path_test role" do
      expect{ QB::Role.require not_in_path_role_name }.to \
        raise_error QB::Role::NoMatchesError
    end # can't find qb/not_in_path_test role
    
    context "when test/roles_not_in_path added to QB::Role::PATH" do
      before(:each) { QB::Role::PATH.unshift roles_not_in_path_dir }
      
      describe 'QB::Role::PATH' do
        subject { QB::Role::PATH }
        it { is_expected.to include roles_not_in_path_dir }
      end # QB::Role::PATH
      
      describe "<QB::Role 'qb/not_in_path_test'>" do
        subject { QB::Role.require not_in_path_role_name }
        
        it_behaves_like QB::Role, and_is_expected: {
          to: {
            have_attributes: {
              name: 'qb/not_in_path_test',
              namespace: 'qb',
            }
          }
        }
        
        context "when QB::Role::PATH is reset again" do
          before { QB::Role.reset_path! }
          
          describe 'QB::Role::PATH' do
            subject { QB::Role::PATH }
            it { is_expected.not_to include roles_not_in_path_dir }
          end # QB::Role::PATH
          
          include_examples 'QB::Role::PATH', is_expected: {
            not_to: {
              include: 'qb/not_in_path_test'
            }
          }
          
          it "can't find qb/not_in_path_test role again" do
            expect{ QB::Role.require not_in_path_role_name }.to \
              raise_error QB::Role::NoMatchesError
          end
        end # after roles path reset
        
      end # test/roles_not_in_path/qb/not_in_path_test
      
    end # test/roles_not_in_path added to QB::Role::PATH
    
  end # roles path
  
end # QB::Role

