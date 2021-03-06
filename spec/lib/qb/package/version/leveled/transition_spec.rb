describe "QB::Package::Version::Leveled#transition" do
  describe "transitioning level" do
    subject {
      ->( level, string, **options ) {
        QB::Package::Version.from( string ).transition_to level, **options
      }
    }


    # to dev
    # ========================================================================
    #
    # Bump from any version level to dev level.
    #
    describe "to dev" do
      subject { super().curry[:dev] }

      context "from release" do
        called_with '0.1.2' do
          it "should transition 'forward' to dev of next release 0.1.3-dev" do
            expect( subject.semver ).to eq '0.1.3-dev'
          end
        end
      end # from release

      context "from release-candidate (rc)" do
        called_with '0.1.2-rc.0' do
          it "should transition 'back' to dev version 0.1.2-dev" do
            expect( subject.semver ).to eq '0.1.2-dev'
          end
        end
      end # from release-candidate

      context "from dev version" do
        it "should fail" do
          expect {
            QB::Package::Version.from( '0.1.2-dev' ).transition_to :dev
          }.to raise_error QB::VersionError
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
          describe_group "Failures" do
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
          end # Group "failures" Description


          describe_group "Successes" do
            subject {
              super().call string, existing_versions: existing_versions
            }

            context_where existing_versions: '0.1.2-rc.3' do
              it_behaves_like QB::Package::Version, and_is_expected: {
                to: {
                  have_attributes: {
                    major: 0,
                    minor: 1,
                    patch: 2,
                    prerelease: ['rc', 4],
                    level: 'rc',
                    build: [],
                    release: '0.1.2',
                    semver: '0.1.2-rc.4',
                  }
                }
              }
            end # existing_versions: '0.1.2-rc.3'

            context_where(
              existing_versions: [
                '0.1.1-rc.0',
                '0.1.1-rc.1',
                '0.1.1',
                '0.1.2-rc.0',
              ].join( "\n" )
            ) do
              it_behaves_like QB::Package::Version, and_is_expected: {
                to: {
                  have_attributes: {
                    semver: '0.1.2-rc.1',
                  }
                }
              }
            end # existing_versions: '0.1.2-rc.3'

            context_where(
              existing_versions: [
                '0.1.1-rc.0',
                '0.1.1-rc.1',
                '0.1.1',
              ].join( "\n" )
            ) do
              it_behaves_like QB::Package::Version, and_is_expected: {
                to: {
                  have_attributes: {
                    semver: '0.1.2-rc.0',
                  }
                }
              }
            end # existing_versions: '0.1.2-rc.3'
          end # Group "Successes" Description
        end # string: '0.1.2-dev'
      end # from dev


      context "from rc" do
        called_with "0.1.2-rc.0" do
          it "should transition 'forward' to next rc version 0.1.2-rc.1" do
            expect( subject.semver ).to eq '0.1.2-rc.1'
          end
        end
      end # from rc

      context "from release" do
        it "should fail" do
          expect {
            QB::Package::Version.from( '0.1.2' ).transition_to :rc
          }.to raise_error QB::VersionError
        end
      end # from release

    end # to release-candidate (rc)


    # to release
    # =====================================================================
    #
    describe "to release" do
      subject { super().curry[:release] }

      describe "from dev" do
        it "should fail" do
          expect {
            QB::Package::Version.from( '0.1.2-dev' ).transition_to :release
          }.to raise_error QB::VersionError
        end
      end # from dev

      context "from rc" do
        describe_called_with "0.1.2-rc.0" do
          it "should transition to release 0.1.2" do
            is_expected.to be_a( QB::Package::Version ).
              and have_attributes semver: '0.1.2'
          end
        end
      end # from rc

      context "from release" do
        it "should fail" do
          expect {
            QB::Package::Version.from( '0.1.2' ).transition_to :release
          }.to raise_error QB::VersionError
        end
      end # from release
    end # to release
  end # to level

end # QB::Package::Version#transition
