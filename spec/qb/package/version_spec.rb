# Spec for {QB::Package::Version}

require 'spec_helper'

RSpec.shared_context :version_everything_dev do
  let(:raw) { '0.1.2-dev.3+master.0a1b2c3d' }
  let(:version) { QB::Package::Version.from_string raw }
  subject { version }
end


RSpec.shared_context :version_only_major do
  let(:raw) { '1' }
  let(:version) { QB::Package::Version.from_string raw }
  subject { version }
end # version with only major


RSpec.shared_context :version_gem_style do
  let(:raw) { '0.1.2.dev.3' }
  let(:version) { QB::Package::Version.from_string raw }
  subject { version }
end #:version_gem_style

RSpec.shared_context :version_bad_gem_style do
  let(:raw) { '0.1.2.3.dev.4' }
end #:version_gem_style


RSpec.shared_context :version_with_build_info do
  let(:raw) { '0.1.2-dev.0+master.aaabbbc.20170101T000000Z' }
  let(:version) { QB::Package::Version.from_string raw }
  subject { version }
end #:version_with_build_info


describe QB::Package::Version do
  
  describe ".new" do
    context "bad args" do
      it "Fails when raw is not a string or nil" do
        expect {
          QB::Package::Version.new raw: 1, major: 0
        }.to raise_error TypeError
      end
    end # bad args
    
  end # .new
  
  
  describe '.from_string' do
    
    context "dev version with everything" do
      include_context :version_everything_dev
      
      it "has major 0" do
        expect(subject.major).to be 0
      end
      
      it "has minor 1" do
        expect(subject.minor).to be 1
      end
      
      it "has patch 2" do
        expect(subject.patch).to be 2
      end
      
      it "has prerelease ['dev', 3]" do
        expect(subject.prerelease).to eq ['dev', 3]
      end
      
      it "has build ['master', '0a1b2c3d']" do
        expect(subject.build).to eq ['master', '0a1b2c3d']
      end
      
      it "has release 0.1.2" do
        expect(subject.release).to eq "0.1.2"
      end
    end # version with major, minor, patch, prerelease, build
    
    
    context "version with only major" do
      include_context :version_only_major
      
      it "has major 1" do
        expect(subject.major).to be 1
      end
      
      it "has minor 0" do
        expect(subject.minor).to be 0
      end
      
      it "has patch 0" do
        expect(subject.patch).to be 0
      end
    end # "version with only major"
    
    
    context "gem-style version with 4 release segments" do
      it {
        expect {
          QB::Package::Version.from_string '1.2.3.4.dev.5'
        }.to raise_error ArgumentError
      }
    end # gem-style version with 4 release segments
    
    
  end # .from_string
  
  
  describe ".from_hash" do
    context "dev version with everything" do
      include_context :version_everything_dev
      
      let(:hash) { version.to_h }
      subject { QB::Package::Version.from_h hash}
      
      it "is equal to original version" do
        expect(version == subject).to be true
      end
    end # dev version with everything
  end # .from_hash
  
  
  
  describe "#to_a" do
    
    context "dev version with everything" do
      include_context :version_everything_dev
      
      it do
        expect(subject.to_a).to eq [0, 1, 2, ['dev', 3], ['master', '0a1b2c3d']]
      end
    end # dev version with everything
    
    context "version with only major" do
      include_context :version_only_major
      
      it do
        expect(subject.to_a).to eq [1, 0, 0, [], []]
      end
    end # version with only major
    
  end # #to_a
  
  
  describe "#release" do
    context "version with only major" do
      include_context :version_only_major
      
      it "zero defaults minor and patch in release" do
        expect(subject.release).to eq "1.0.0"
      end
    end # version with only major
  end # #release
  
  
  describe "#release_version" do
    context "dev version with everything" do
      include_context :version_everything_dev
      
      subject { version.release_version }
      
      it { is_expected.to eq QB::Package::Version.from_string '0.1.2' }
    end # dev version with everything
    
    context "version with only major" do
      include_context :version_only_major
      
      subject { version.release_version }
      
      it "zero defaults minor and patch" do
        expect(subject.minor).to be 0
        expect(subject.patch).to be 0
      end
      
      it "has #raw of 1.0.0" do
        expect(subject.raw).to eq '1.0.0'
      end
      
      it "has #release of 1.0.0" do
        expect(subject.release).to eq '1.0.0'
      end
    end # version with only major
  end # #release_version
  
  
  describe "#build_version" do
    context "dev version with everything" do
      include_context :version_everything_dev
      
      context "clean" do
        subject {
          version.build_version branch: 'blah',
                                ref: 'aaabbbc',
                                time: Time.new(2017, 1, 1, 0, 0, 0, '+00:00')
        }
        
        it "replaces build info" do
          expect(subject.build).to eq ['blah', 'aaabbbc', "20170101T000000Z"]
        end
      end # clean
      
      context "dirty" do
        subject {
          version.build_version branch: 'blah',
                                ref: 'aaabbbc',
                                time: Time.new(2017, 1, 1, 0, 0, 0, '+00:00'),
                                dirty: true
        }
        
        it "replaces build info" do
          expect(subject.build).to eq(
            ['blah', 'aaabbbc', 'dirty', "20170101T000000Z"]
          )
        end
      end # dirty
      
    end # dev version with everything
    
  end # #build_version
  
  
  
  describe "#semver" do
    context "Ruby Gems-style version 0.1.2.dev.3" do
      include_context :version_gem_style
      
      it do
        expect(subject.semver).to eq "0.1.2-dev.3"
      end
    end # Ruby Gems-style version 0.1.2.dev.3
  end # #semver
  
  
  # Docker Tag
  # ---------------------------------------------------------------------
  
  describe "#docker_tag" do
    context "version with build info" do
      include_context :version_with_build_info
      
      it "forms the correct Docker image tag" do
        expect(subject.docker_tag).to eq \
          "0.1.2-dev.0_master.aaabbbc.20170101T000000Z"
      end
    end # version with build info
  end # #docker_tag
  
  
  describe ".from_docker_tag" do
    context "version with build info" do
      include_context :version_with_build_info
      
      it "re-parses into an equal version" do
        expect(
          QB::Package::Version.from_docker_tag version.docker_tag
        ).to eq version
      end
    end # version with build info
  end # .from_docker_tag
  
  
  
  # Language Interface
  # =====================================================================
  
  describe "#==" do
    
    context "version with only major" do
      include_context :version_only_major
      
      it "is equal to another parse of itself" do
        expect(subject == QB::Package::Version.from_string(raw)).to be true
      end
      
      it "is equal to version where missing minor and patch are 0" do
        expect(
          subject == QB::Package::Version.from_string('1.0.0')
        ).to be true
      end
    end # version with only major
    
  end # #==
  
  
  describe "Language Integration" do
  # =====================================================================
    describe "Array#uniq" do
      context "version with only major" do
        include_context :version_only_major
        
        it "does reduce parses of the same raw version" do
          expect(
            [subject, QB::Package::Version.from_string(raw)].uniq.length
          ).to be 1
        end
      end # version with only major
      
    end # Array#uniq
    
  end # Language Integration
  
  
end # QB::Package::Version

