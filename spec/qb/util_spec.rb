require 'spec_helper'

describe QB::Util do
  describe '.words' do
    words = QB::Util.method :words
    
    it "splits a role name" do
      expect(words.call "qb.git_update_submodule").to(
        eq ['qb', 'git', 'update', 'submodule']
      )
    end
    
    it "splits a role path" do
      expect(words.call "./ansible/roles/nrser.substring").to(
        eq ['ansible', 'roles', 'nrser', 'substring']
      )
    end
  end # .words
  
  describe '.words_start_with?' do
    f = QB::Util.method :words_start_with?
    
    it 'splits some shit' do
      expect(f.('qb.release_gem', 'rel_g')).to be true
      expect(f.('qb.release_gem', 'q-r-g')).to be true
      expect(f.('qb.release_gem', 'g')).to be true
      expect(f.('qb.release_gem', 'gm')).to be false
      expect(f.("./ansible/roles/nrser.substring", 'n.subs')).to be true
    end
  end # .words_start_with?
end # QB::Util