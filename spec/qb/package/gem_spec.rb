##
# Spec for {QB::Package::Gem}
##

require 'spec_helper'

require 'qb/package/gem'

describe "QB::Package::Gem" do
  subject { QB::Package::Gem }
  
  describe ".gemspec_path" do
  # =====================================================================
    
    subject { super().method :gemspec_path }
    
    context "QB::ROOT" do
      subject { super().call QB::ROOT }
      
      it "returns //qb.gemspec" do
        is_expected.to eq( QB::ROOT / 'qb.gemspec' )
      end
      
    end # QB::ROOT
    
  end # .gemspec_path
  
  
  describe ".from_root_path" do
  # =====================================================================
  
    subject { super().method :from_root_path }
    
    context "QB::ROOT" do
      subject { super().call QB::ROOT }
      
      it { is_expected.to be_a QB::Package::Gem }
      
      describe "#ref_path" do
        subject { super().ref_path }
        it { is_expected.to be QB::ROOT }
      end # #ref_path
      
      describe "#gemspec_path" do
        subject { super().gemspec_path }
        it { is_expected.to eq( QB::ROOT / 'qb.gemspec' ) }
      end # #gemspec_path
      
      describe "#spec" do
        subject { super().spec }
        it 'should be a Gem::Specification' do
          is_expected.to be_a ::Gem::Specification
        end
      end # #spec
      
      describe "#name" do
        subject { super().name }
        it { is_expected.to eq 'qb' }
      end # #name
      
      describe "#version" do
        subject { super().version }
        it { is_expected.to be_a QB::Package::Version }
      end # #version
      
    end # QB::ROOT
    
  end # .from_root_path
  
end # QB::Package::Gem
