require 'spec_helper'

require 'nrser/refinements'
using NRSER


# QB::Package::Version#extract
# ========================================================================
# 
describe "QB::Package::Version.extract" do
  subject { QB::Package::Version.method :extract }
  
  some_legit_version_strings = [
    '0.1.2',
    '0.1.2-dev.3+master.0a1b2c3d',
    '0.1.2.dev.3',
    '12.34.567-rc.123',
    '12.34.567-rc.123+blah',
  ]
  
  describe_section "strings that are just versions" do
  # ========================================================================
    
    describe_group "stuff that works" do
      some_legit_version_strings.each do |string|
        describe_called_with string do
          it {
            is_expected.to be_a( Array ).
              and have_attributes(
                length: 1,
                first: be_a( QB::Package::Version ).
                  and( eq QB::Package::Version.from( string ) ),
              )
          }
        end # called with string
      end
    end # stuff that works
    
    
    describe_group "stuff that doesn't work" do
      
      describe_group "bare numbers" do
        [ "0", "1", "2423423" ].each do |string|
          describe_called_with string do
            it { is_expected.to eq [] }
          end # called with string
        end
      end # Group "bare numbers" Description
      
    end # Group "stuff that doesn't work"
    
    
  end # section strings that are just versions
  # ************************************************************************
  
  
  describe_section "`git tag`-type output" do
  # ========================================================================

      string = <<-END.dedent
        2017-11-20_BEFORE_reorg-service-dirs
        http-frontend/v0.1.0
        resque-web/v0.1.0
        v0.1.0
        v0.1.1
        v0.1.10-rc.0
        v0.1.10-rc.1
        v0.1.10-rc.2
        v0.1.10-rc.3
        v0.1.11-rc.0
        v0.1.11-rc.1
        v0.1.2
        v0.1.3
        v0.1.4
        v0.1.5
        v0.1.6
        v0.1.7
        v0.1.8
        v0.1.9
        v0.2.0-rc.0
        web/v0.2.0
        web/v0.2.0-rc.1
        web/v0.2.0-rc.10
        web/v0.2.0-rc.11
        web/v0.2.0-rc.12
        web/v0.2.0-rc.13
        web/v0.2.0-rc.14
        web/v0.2.0-rc.15
        web/v0.2.0-rc.2
        web/v0.2.0-rc.3
        web/v0.2.0-rc.4
        web/v0.2.0-rc.5
        web/v0.2.0-rc.6
        web/v0.2.0-rc.7
        web/v0.2.0-rc.8
        web/v0.2.0-rc.9
        web/v0.2.1-rc.0
      END
      
      expected = [
        '0.1.0',
        '0.1.0',
        '0.1.0',
        '0.1.1',
        '0.1.10-rc.0',
        '0.1.10-rc.1',
        '0.1.10-rc.2',
        '0.1.10-rc.3',
        '0.1.11-rc.0',
        '0.1.11-rc.1',
        '0.1.2',
        '0.1.3',
        '0.1.4',
        '0.1.5',
        '0.1.6',
        '0.1.7',
        '0.1.8',
        '0.1.9',
        '0.2.0-rc.0',
        '0.2.0',
        '0.2.0-rc.1',
        '0.2.0-rc.10',
        '0.2.0-rc.11',
        '0.2.0-rc.12',
        '0.2.0-rc.13',
        '0.2.0-rc.14',
        '0.2.0-rc.15',
        '0.2.0-rc.2',
        '0.2.0-rc.3',
        '0.2.0-rc.4',
        '0.2.0-rc.5',
        '0.2.0-rc.6',
        '0.2.0-rc.7',
        '0.2.0-rc.8',
        '0.2.0-rc.9',
        '0.2.1-rc.0',
      ].map { |s| QB::Package::Version.from s }
      
    subject { super().call string }
    
    it "extracts and parses all the versions in order found" do
      expected.each_with_index do |expected, index|
        expect( subject[index] ).to eq expected
      end
    end
    
  end # section `git tag`-type output
  # ************************************************************************
  
  
end # QB::Package::Version#extract
