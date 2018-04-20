require 'qb/docker'

describe_spec_file(
  spec_path: __FILE__,
  class: QB::Docker::Image::Tag,
) do
  
  describe_section "accepts" do
  # ========================================================================
    
    describe_section "from non-version string tags" do
    # ========================================================================
      
      describe_instance source: 'latest' do
        it do
          is_expected.to be_a described_class
        end
        
        it do
          is_expected.to have_attributes \
            version: nil,
            source: 'latest',
            to_s: 'latest'
        end
      end
      
    end # from section non-version string tags
    # ************************************************************************
    
    
    describe_section "from version string tags" do
    # ========================================================================
      
      describe_instance source: '0.1.2' do
        it do
          is_expected.to be_a described_class
        end
        
        it do
          is_expected.to have_attributes \
            version: be_a( QB::Package::Version ).and(
              have_attributes(
                major: 0,
                minor: 1,
                patch: 2,
              )
            ),
            source: '0.1.2',
            to_s: '0.1.2'
        end
      end
      
    end # from section version string tags
    # ************************************************************************
    
  end # section accepts
  # ************************************************************************
  
  
  
  describe_section "rejects" do
  # ========================================================================
    
    
    context "no source or version" do
      # describe_instance( {} ) do
      #   it do
      #     expect { subject }.to raise_error TypeError, /failed type check/
      #   end
      # end
      it do
        expect {
          QB::Docker::Image::Tag.new
        }.to raise_error TypeError
      end
    end # no source or version
    
    
    
  end # section rejects
  # ************************************************************************
  

  
end # spec file
