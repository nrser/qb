require 'spec_helper'

describe QB::Repo::Git do
  describe ".from_path" do
    context "QB root" do
      
      let(:git) { QB::Repo::Git.from_path QB::ROOT }
      
      it {
        expect(git).to be_a QB::Repo::Git
      }
      
      it "has a user with name and email" do
        expect(git.user).to be_a QB::Repo::Git::User
        expect(git.user.name).to be_a String
        expect(git.user.email).to be_a String
      end
      
    end # QB root
  end # .from_path
end # QB::Repo::Git

