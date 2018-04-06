describe_spec_file(
  spec_path: __FILE__,
  class: QB::Path,
) do
  context "directory path" do
  
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
        subject { super().to_data }
        
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
          subject { super().fetch 'git' }
          
          include_examples "expect subject", to: {
            be_a: Hash,
            include: {
              'root_path' => QB::ROOT.to_s,
              'name' => 'qb',
            }
          }
        end # .git
        
      end # #to_data
    end # context raw: QB::ROOT
    
    
    context "path that is not in a Git repo" do
      let( :path )  { Dir.mktmpdir 'qb_not_git_dir' }
      subject       { QB::Path.new raw: path }
      after         { FileUtils.rm_rf path }
      
      it_behaves_like QB::Path, and_is_expected: {
        to: {
          have_attributes: {
            git: nil,
          }
        }
      }
    end # path that is not in a Git repo
    
    
    context "path that is not a Gem root" do
      let( :path )  { Dir.mktmpdir 'qb_not_gem_root' }
      subject       { QB::Path.new raw: path }
      after         { FileUtils.rm_rf path }
      
      it_behaves_like QB::Path, and_is_expected: {
        to: {
          have_attributes: {
            gem: nil,
          }
        }
      }
    end # path that is not in a Git repo
  
  end # directory path
  
  # ************************************************************************
  
  
  context "file path" do
  # ========================================================================
    
    context "//qb.gemspec file" do
      let( :path )  { QB::ROOT / 'qb.gemspec' }
      subject       { QB::Path.new path }
      
      it_behaves_like QB::Path, and_is_expected: {
        to: {
          have_attributes: {gem: nil},
        }
      }
      
      describe "#git" do
        subject { super().git }
        it { is_expected.to be_a QB::Repo::Git }
      end # #git
      
    end # //qb.gemspec file
    
    
  end # file path
  
  # ************************************************************************
  
  
end # QB::Repo::Git
