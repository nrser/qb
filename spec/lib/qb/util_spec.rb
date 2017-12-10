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
  
  describe '.resolve' do
    f = QB::Util.method :resolve
    
    it "resolves against pwd by default" do
      expect(f.()).to eq Pathname.pwd
      expect(f.('x')).to eq Pathname.pwd.join('x') 
    end
    
    it "resolves abs path to itself" do
      expect(f.('/usr/bin')).to eq Pathname.new('/usr/bin')
      expect(f.('/etc', '/usr/bin')).to eq Pathname.new('/usr/bin')
    end
  end # .resolve
end # QB::Util