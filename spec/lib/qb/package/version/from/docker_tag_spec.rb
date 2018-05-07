describe_spec_file(
  spec_path: __FILE__,
  module: QB::Package::Version::From,
  method: :docker_tag,
) do
  describe_section "rejects" do
  # ========================================================================
    
    context "empty string" do
      describe_called_with '' do
        it do
          expect{ subject }.to raise_error TypeError
        end
      end # called with ''
    end
    
  end # section rejects
  # ************************************************************************
  
  
  describe_section "accepts" do
  # ========================================================================
    
    describe_called_with "0.2.1_openresty-openresty.1.11.2.4.xenial" do
      it_behaves_like QB::Package::Version, and_is_expected: {
        to: {
          have_attributes: {
            major: 0,
            minor: 2,
            patch: 1,
            prerelease: [],
            level: 'release',
            build: ['openresty-openresty', 1, 11, 2, 4, 'xenial'],
            release: '0.2.1',
            semver: '0.2.1+openresty-openresty.1.11.2.4.xenial',
          }
        }
      }
    end # Called With "0.2.1_openresty-openresty.1.11.2.4.xenial" Description
    
    
    describe_called_with "0.2.1_ruby.2.3.6" do
      it_behaves_like QB::Package::Version, and_is_expected: {
        to: {
          have_attributes: {
            major: 0,
            minor: 2,
            patch: 1,
            prerelease: [],
            level: 'release',
            build: ['ruby', 2, 3, 6],
            release: '0.2.1',
            semver: '0.2.1+ruby.2.3.6',
          }
        }
      }
    end
    
    
    describe_called_with "0.2.1_ruby.2.3.6" do
      it_behaves_like QB::Package::Version, and_is_expected: {
        to: {
          have_attributes: {
            major: 0,
            minor: 2,
            patch: 1,
            prerelease: [],
            level: 'release',
            build: ['ruby', 2, 3, 6],
            release: '0.2.1',
            semver: '0.2.1+ruby.2.3.6',
          }
        }
      }
    end
    
  end # section accepts
  # ************************************************************************
  
end # QB::Package::Version
