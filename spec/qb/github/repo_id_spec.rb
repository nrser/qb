require 'spec_helper'

describe_class QB::GitHub::RepoID do
  
  describe_instance name: 'qb', owner: 'nrser' do
    
    it { |example|
      is_expected.to be_a( described_class ).
        and have_attributes(
          name: 'qb',
          owner: 'nrser',
          path: "nrser/qb",
      )
    }
    
    describe_method :git_url do
      describe_called_with :ssh do
        it { is_expected.to eq 'git@github.com:nrser/qb.git' }
      end # called with :ssh
      
      describe_called_with :https do
        it { is_expected.to eq 'https://github.com/nrser/qb.git' }
      end # called with :ssh
      
    end # Method :git_url Description
    
  end
  
end
