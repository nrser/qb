require 'spec_helper'

describe QB::Path do
  context 'raw: QB::ROOT' do
    subject { QB::Path.new raw: QB::ROOT }
    
    it_behaves_like QB::Path, and_is_expected: {
      to: {
        have_attributes: {
          raw: QB::ROOT,
          expanded?: true,
        }
      }
    }
    
    describe '#to_data' do
      refine_subject :to_data
      
      include_examples "expect subject", to: {
        be_a: Hash,
        include: {
          '__class__' => QB::Path.name,
          'raw' => QB::ROOT.to_s,
          'exists' => true,
          'is_expanded' => true,
        }
      }
      
    end # #to_data
    
  end # context raw: QB::ROOT
end # QB::Repo::Git

