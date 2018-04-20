require 'qb/docker'

describe_spec_file(
  spec_path: __FILE__,
  class: QB::Docker::Image::Name,
) do
  
  describe_section "loading" do
  # ========================================================================
    
    describe_method :from_s do
      describe_group "accepts" do
        
        shared_examples described_class do |**attrs|
          attrs = {
            registry_server: nil,
            port: nil,
            repository: nil,
            name: nil,
          }.merge attrs
          
          it { is_expected.to be_a described_class }
          it { is_expected.to have_attributes attrs }
        end # example name
        
        
        describe_called_with "neilio" do
          include_examples described_class,
            name: 'neilio'
        end
        
        
        describe_called_with "nrser/neilio" do
          include_examples described_class,
            repository: 'nrser',
            name: 'neilio'
        end
        
        
        describe_called_with "nrser/neilio/yo/ho/ho" do
          include_examples described_class,
            repository: 'nrser',
            name: 'neilio/yo/ho/ho'
        end
        
        
        describe_called_with "docker.nrser.com:8888/nrser/neilio" do
          include_examples described_class,
            registry_server: 'docker.nrser.com',
            port: 8888,
            repository: 'nrser',
            name: 'neilio'
        end # called with "docker.nrser.com:8888/nrser/neilio"
        
        
        describe_called_with "nrser/neilio:latest" do
          include_examples described_class,
            repository: 'nrser',
            name: 'neilio'
            
          describe_attribute :tag do
            it { is_expected.to be_a QB::Docker::Image::Tag }
            
            it do
              is_expected.to have_attributes \
                version: nil,
                source: 'latest',
                to_s: 'latest'
            end
          end # Attribute tag Description
          
        end # called with "nrser/neilio:latest"
        
        
        describe_called_with "nrser/neilio:0.1.2" do
          include_examples described_class,
            repository: 'nrser',
            name: 'neilio'
            
          describe_attribute :tag do
            it { is_expected.to be_a QB::Docker::Image::Tag }
            
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
          end # Attribute tag Description
          
        end # called with "nrser/neilio:latest"
        
      end
    end # Method from_s Description
  end # section loading
  # ************************************************************************
  
end # spec file
