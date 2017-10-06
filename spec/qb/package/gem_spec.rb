##
# Spec for {QB::Package::Gem}
##

require 'spec_helper'

require 'qb/package/gem'

describe "QB::Package::Gem" do
  subject { QB::Package::Gem }
  
  describe ".gemspec_path" do
  # =====================================================================
    
    refine_subject :method, :gemspec_path
    
    context "QB::ROOT" do
      refine_subject :call, QB::ROOT
      
      it "returns //qb.gemspec" do
        is_expected.to eq( QB::ROOT / 'qb.gemspec' )
      end
      
    end # QB::ROOT
    
  end # .gemspec_path
  
  
  describe ".from_root_path" do
  # =====================================================================
  
    refine_subject :method, :from_root_path
    
    context "QB::ROOT" do
      refine_subject :call, QB::ROOT
      
      it { is_expected.to be_a QB::Package::Gem }
      
      describe "#ref_path" do
        refine_subject :ref_path
        it { is_expected.to be QB::ROOT }
      end # #ref_path
      
      describe "#gemspec_path" do
        refine_subject :gemspec_path
        it { is_expected.to eq( QB::ROOT / 'qb.gemspec' ) }
      end # #gemspec_path
      
      describe "#spec" do
        refine_subject :spec
        it 'should be a Gem::Specification' do
          is_expected.to be_a ::Gem::Specification
        end
      end # #spec
      
      describe "#name" do
        refine_subject :name
        it { is_expected.to eq 'qb' }
      end # #name
      
      describe "#version" do
        refine_subject :version
        it { is_expected.to be_a QB::Package::Version }
      end # #version
      
    end # QB::ROOT
    
  end # .from_root_path
  
end # QB::Package::Gem
