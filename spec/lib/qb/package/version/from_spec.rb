describe_spec_file(
  spec_path: __FILE__,
  class: QB::Package::Version,
) do
  describe_method :from do
    describe_section "rejects" do
    # ========================================================================
      
      context "empty string" do
        describe_called_with '' do
          it do
            expect{ subject }.to raise_error TypeError, /failed type check/
          end
        end # called with ''
      end
      
      
      context "gem-style version with 4 release segments" do
        describe_called_with '1.2.3.4.dev.5' do
          it do
            expect { subject }.to raise_error ArgumentError
          end
        end
      end # gem-style version with 4 release segments
      
    end # section rejects
    # ************************************************************************
    
    
    describe_section "accepts" do
    # ========================================================================
      
      context "dev version with everything" do
        describe_called_with '0.1.2-dev.3+master.0a1b2c3d' do
          it_behaves_like QB::Package::Version, and_is_expected: {
            to: {
              have_attributes: {
                major: 0,
                minor: 1,
                patch: 2,
                prerelease: ['dev', 3],
                level: 'dev',
                build: ['master', '0a1b2c3d'],
                release: '0.1.2',
                semver: '0.1.2-dev.3+master.0a1b2c3d',
              }
            }
          }
        end
      end # version with major, minor, patch, prerelease, build
      
      
      context "version with only major" do
        describe_called_with '1' do
          it_behaves_like QB::Package::Version, and_is_expected: {
            to: {
              have_attributes: {
                major: 1,
                minor: 0,
                patch: 0,
                prerelease: [],
                prerelease?: false,
                level: 'release',
                build: [],
                build?: false,
                release: '1.0.0',
                semver: '1.0.0',
              }
            }
          }
        end
      end # "version with only major"
      
      
      context "Release version" do
        describe_called_with '0.1.2' do
          it_behaves_like QB::Package::Version, and_is_expected: {
            to: {
              have_attributes: {
                major: 0,
                minor: 1,
                patch: 2,
                prerelease: [],
                prerelease?: false,
                level: 'release',
                build: [],
                build?: false,
                release: '0.1.2',
                semver: '0.1.2',
              }
            }
          }
        end
      end # Release version
      
      
      context "Build with no prerelease" do
        describe_called_with '0.1.2+master.0a1b2c3d' do
          it_behaves_like QB::Package::Version, and_is_expected: {
            to: {
              have_attributes: {
                major: 0,
                minor: 1,
                patch: 2,
                prerelease: [],
                prerelease?: false,
                build: ['master', '0a1b2c3d'],
                build?: true,
                release: '0.1.2',
                semver: '0.1.2+master.0a1b2c3d',
              }
            }
          }
        end
      end # Build with no prerelease
      
    end # section accepts
    # ************************************************************************
  end # .from
  # ************************************************************************
end # QB::Package::Version
