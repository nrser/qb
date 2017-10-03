##
# Spec for {QB::Package::Gem}
##

require 'spec_helper'

require 'qb/package/gem'

describe "QB::Package::Gem" do
  subject { QB::Package::Gem }
  
  describe ".gemspec_path" do
    refine_subject :method, :gemspec_path
    
    context "QB::ROOT" do
      refine_subject :call, QB::ROOT
      
      it "returns //qb.gemspec" do
        is_expected.to eq( QB::ROOT / 'qb.gemspec' )
      end
      
    end # QB::ROOT
    
  end # .gemspec_path
  
end # QB::Package::Gem

