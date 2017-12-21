# Describe the `qb/rspex/generate` role.
# 
# This causes {Support::Ext::QBRole} RSpec extensions to be mixed in, which
# provides a host of helpers for building and running the QB Role through
# the `cmds` gem.
# 
describe_qb_role 'qb/rspex/generate' do
  # Work with a temp copy of `//test/packages/gems/test_gem`
  include_context :temp_gem
  
  # Add the `--class=TestGem::SomeClass` option
  # 
  def qb_role_opts
    { class: 'TestGem::SomeClass' }
  end
  
  # Provide the temp gem's root path as the QB run directory (`qb_dir`).
  # 
  def qb_role_dir
    temp_gem_root
  end
  
  before :all do
    # Expected generated spec file path
    @spec_path = temp_gem_root / 'spec' / 'test_gem' / 'some_class_spec.rb'
  end
  
  
  describe "generating spec for a class" do
    
    context "just `--class=TestGem::SomeClass` option" do
    
      before :all do
        temp_gem_reset!
        run_cmd!
      end # before :all
      
      
      describe "command exit status" do
        subject { @exit_status }
        
        it "should be 0 (success)" do
          is_expected.to be 0
        end
      end # "command exit code"
      
      
      describe "spec path" do
        subject { @spec_path }
        
        it "should be a file" do
          is_expected.to have_attributes file?: true
        end
      end # "spec path"
      
      
      describe "spec file contents" do
        subject { @spec_path.read }
        
        it "should require `spec_helper`" do
          is_expected.to match /^require\ \"spec_helper\"$/
        end
      end # "spec file contents"
      
    end # context "just `--class=TestGem::SomeClass` option"
    
    
    context "explicit `--require=other_helper` option" do
      
      # Add `--require=other_helper` option to cmd opts
      def qb_role_opts
        super().merge require: 'other_helper'
      end
      
      before :all do
        temp_gem_reset!
        run_cmd!
      end
      
      describe "spec file contents" do
        subject { @spec_path.read }
        
        it "should require `other_helper`" do
          is_expected.to match /^require\ \"other_helper\"$/
        end
        
        it "should not require `spec_helper`" do
          is_expected.not_to match /^require\ \"spec_helper\"$/
        end
      end # "spec file contents"
      
    end # context "explicit `--require=other_helper` option"
    
  end # "generating spec for a class"
end # qb_role 'qb/rspec/generate'
