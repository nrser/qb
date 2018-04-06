##
# Spec for {QB::Package::Gem}
##

require 'nrser/refinements'
using NRSER

require 'qb/package/gem'

describe_spec_file(
  spec_path: __FILE__,
  class: QB::Package::Gem,
) do
  
  describe_method :gemspec_path do
  # =====================================================================
    
    called_with QB::ROOT do
      it "returns //qb.gemspec" do
        is_expected.to eq( QB::ROOT / 'qb.gemspec' )
      end
    end # QB::ROOT
    
  end # .gemspec_path
  
  
  describe_method :from_root_path do
  # =====================================================================
    
    subject { super().method :from_root_path }
    
    called_with QB::ROOT do
      it {
        is_expected.to \
          be_a( QB::Package::Gem ).
          and(
            have_attributes(
              ref_path: QB::ROOT,
              gemspec_path: ( QB::ROOT / 'qb.gemspec' ),
              name: 'qb',
              version: be_a( QB::Package::Version ),
              
              # Repo
              in_repo?: true,
              repo: be_a( QB::Repo ).and( be_a QB::Repo::Git ),
              repo_rel_path: Pathname.new( '.' ),
              version_tag_prefix: 'v',
            )
          )
      }
      
      describe "#spec" do
        subject { super().spec }
        it 'should be a Gem::Specification' do
          is_expected.to be_a ::Gem::Specification
        end
      end # #spec
      
    end # QB::ROOT
    
    called_with TEST_GEM_ROOT_PATH do
      it {
        is_expected.to \
          be_a( QB::Package::Gem ).
          and have_attributes \
            in_repo?: true,
            repo: (
              be_a( QB::Repo::Git ).
              and( have_attributes root_path: QB::ROOT )
            ),
            version_tag_prefix: 'test/packages/gems/test_gem/v',
            version_tag: 'test/packages/gems/test_gem/v0.1.0'
      }
    end # called_with( QB::ROOT / 'test' / 'packages' / 'gems' / 'test_gem' )
    
  end # .from_root_path
  
end # QB::Package::Gem
