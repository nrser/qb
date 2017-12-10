require 'spec_helper'

describe QB::Repo::Git do
  describe ".from_path" do
    context "QB::ROOT" do
      
      subject { QB::Repo::Git.from_path QB::ROOT }
      
      it_behaves_like QB::Repo::Git, and_is_expected: {
        to: {
          have_attributes: {
            ref_path: QB::ROOT,
            
            name: 'qb',
            owner: 'nrser',
            full_name: 'nrser/qb',
            
            clean?: Dir.chdir( QB::ROOT ) {
              `git status --porcelain 2>/dev/null`.chomp.empty?
            },
          }
        }
      }
      
      describe "#user" do
        subject { super().user }
        
        it_behaves_like QB::Repo::Git::User, and_is_expected: {
          to: {
            have_attributes: {
              name: `git config user.name`.chomp,
              email: `git config user.email`.chomp,
            }
          }
        }
      end # #user
      
      describe '#to_data' do
        subject { super().to_data }
        
        include_examples "expect subject", to: {
          be_a: Hash,
          include: {
            '__class__' => QB::Repo::Git::GitHub.name,
            
            'name' => 'qb',
            
            'owner' => 'nrser',
            
            'user' => {
              '__class__' => QB::Repo::Git::User.name,
              'name' => `git config user.name`.chomp,
              'email' => `git config user.email`.chomp,
            },
            'origin' => 'git@github.com:nrser/qb.git',
            
            'is_clean' => Dir.chdir( QB::ROOT ) {
              `git status --porcelain 2>/dev/null`.chomp.empty?
            },
          }
        }
        
      end # #to_data
      
    end # QB::ROOT
  end # .from_path
end # QB::Repo::Git

