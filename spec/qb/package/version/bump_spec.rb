require 'spec_helper'


# QB::Package::Version#bump
# ========================================================================
# 
describe "QB::Package::Version#bump" do
  context "level:" do
    subject {
      ->( level, string ) {
        QB::Package::Version.from_s( string ).bump level: level
      }
    }
    
    
    # to dev
    # ========================================================================
    # 
    # Bump from any version level to dev level.
    # 
    describe "dev" do
      subject { super().curry[:dev] }
      
      context "from release" do
        called_with '0.1.2' do
          it "should bump 'forward' to dev of next release 0.1.3-dev" do
            expect( subject.semver ).to eq '0.1.3-dev'
          end
        end
      end # from release
      
      context "from release-candidate (rc)" do
        called_with '0.1.2-rc.0' do
          it "should bump 'back' to dev version 0.1.2-dev" do
            expect( subject.semver ).to eq '0.1.2-dev'
          end
        end
      end # from release-candidate
      
      context "from dev version" do
        let( :version ) { QB::Package::Version.from_s '0.1.2-dev' }
        subject { version.bump level: :dev }
        
        it "should just return self" do
          is_expected.to be version
        end
      end # from dev 0.1.2-dev
      
    end # dev
    
    
    # to release-candidate (rc)
    # ========================================================================
    # 
    describe "to release-candidate (rc)" do
      subject { super().curry[:rc] }
      
      context "from dev" do
        
        context_where string: '0.1.2-dev' do
          context "`existing_versions` option not provided" do
            it {
              expect { subject.call string }.to raise_error ArgumentError
            }
          end
          
          context_where existing_versions: nil do
            it {
              expect {
                subject.call string, existing_versions: existing_versions
              }.to raise_error ArgumentError
            }
          end # existing_versions: nil
          
        end # string: '0.1.2-dev'
        
        

      end # from dev
      
      context "from rc" do
        called_with "0.1.2-rc.0" do
          it "should bump 'forward' to next rc version 0.1.2-rc.1" do
            expect( subject.semver ).to eq '0.1.2-rc.1'
          end
        end
      end # from rc
      
      context "from release" do
        called_with "0.1.2" do
          it "should bump patch and set rc to 0: 0.1.3-rc.0" do
            expect( subject.semver ).to eq '0.1.3-rc.0'
          end
        end
      end # from release
      
    end # to release-candidate (rc)
    
    
    # to release
    # =====================================================================
    # 
    # describe "to release" do
    #   subject { super().curry[:release] }
    #   
    #   context "from dev" do
    #     it { expect { subject.call '0.1.2-dev' }.to raise_error ArgumentError }
    #   end # from dev
    #   
    #   context "from rc" do
    #     called_with "0.1.2-rc.0" do
    #       it "should bump 'forward' to next rc version 0.1.2-rc.1" do
    #         expect( subject.semver ).to eq '0.1.2-rc.1'
    #       end
    #     end
    #   end # from rc
    #   
    #   context "from release" do
    #     called_with "0.1.2" do
    #       it "should bump patch and set rc to 0: 0.1.3-rc.0" do
    #         expect( subject.semver ).to eq '0.1.3-rc.0'
    #       end
    #     end
    #   end # from release
    #   
    # end # "to release"
    
  
  end # to level
  
end # QB::Package::Version#bump
