require 'spec_helper'

describe QB::Repo::Git do
  describe ".from_path" do
    context "QB::ROOT" do
      
      subject { QB::Repo::Git.from_path QB::ROOT }
      
      it_behaves_like QB::Repo::Git
      
      describe "#user" do
        refine_subject :user
        
        it_behaves_like QB::Repo::Git::User, and_is_expected: {
          to: {
            have_attributes: {
              name: `git config user.name`.chomp,
              email: `git config user.email`.chomp,
            }
          }
        }
      end # #user
      
    end # QB::ROOT
  end # .from_path
end # QB::Repo::Git

