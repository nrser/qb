require 'spec_helper'

describe QB::Path do
  
  context 'raw: QB::ROOT' do
    subject { QB::Path.new raw: QB::ROOT }
    
    it_behaves_like QB::Path, and_is_expected: {
      to: {
        have_attributes: {
          raw: QB::ROOT,
          expanded?: true,
          relative: (
            QB::ROOT.relative_path_from Pathname.getwd
          ),
          realpath?: ( QB::ROOT.realpath == QB::ROOT ),
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
          'is_absolute' => true,
          'is_relative' => false,
          'is_dir' => true,
          'is_file' => false,
          'is_cwd' => (QB::ROOT == Pathname.getwd),
          'relative' => (
            QB::ROOT.relative_path_from( Pathname.getwd ).to_s
          ),
          'realpath' => QB::ROOT.realpath.to_s,
          'is_realpath' => ( QB::ROOT.realpath == QB::ROOT ),
        }
      }
      
      describe "'git' value" do
        refine_subject :fetch, 'git'
        
        include_examples "expect subject", to: {
          be_a: Hash,
          include: {
            'root' => QB::ROOT.to_s,
            'name' => 'qb',
          }
        }
      end # .git
      
    end # #to_data
  end # context raw: QB::ROOT
  
end # QB::Repo::Git

