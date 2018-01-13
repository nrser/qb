describe_spec_file(
  spec_path: __FILE__,
  module: QB::Package::Version::From,
  method: :class_for,
) do
  
  context_where response: QB::Package::Version::Leveled do
    describe "when prerelease and build values are empty (release level)" do
      describe_called_with( {} ) do
        it { is_expected.to be response}
      end # called with {}
      
      describe_called_with prerelease: [], build: [] do
        it { is_expected.to be response }
      end # called with prerelease: ['dev']
    end # "release level"
    
    describe "when prerelease has `dev` first (dev level)" do
      describe_called_with prerelease: ['dev'] do
        it { is_expected.to be response }
      end # called with prerelease: ['dev']
      
      describe_called_with prerelease: ['dev', 0] do
        it { is_expected.to be response }
      end # called with prerelease: ['dev']
      
      describe_called_with prerelease: ['dev'], build: ['master', '1234567'] do
        it { is_expected.to be response }
      end
      
      describe_called_with(
        prerelease: ['dev', 1, 2, 'three'],
        build: ['master', '1234567']
      ) do
        it { is_expected.to be response }
      end
    end # dev level
    
    describe "when prerelease is ('rc', X) for pos. int. X" do
      describe_called_with prerelease: ['rc', 0] do
        it { is_expected.to be response }
      end
      
      describe_called_with prerelease: ['rc', 12345] do
        it { is_expected.to be response }
      end
      
      describe "and there is build info" do
        describe_called_with prerelease: ['rc', 0], build: ['master'] do
          it { is_expected.to be response }
        end
      end # "but it's the only entry"
    end # "when prerelease is ('rc', X) for 0 < X (rc level)"
    
  end # response: QB::Package::Version::Leveled
  
  
  context_where response: QB::Package::Version do
    describe "when prerelease[0] is not 'dev' or 'rc'" do
      describe_called_with prerelease: ['pre'] do
        it { is_expected.to be response }
      end
    end # "when prerelease[0] is not 'dev' or 'rc'"
    
    describe "when prerelease[0] is 'rc'" do
      describe "but [1] is not pos. int." do
        describe_called_with prerelease: ['rc', 'x'] do
          it { is_expected.to be response }
        end
        
        describe_called_with prerelease: ['rc', -1] do
          it { is_expected.to be response }
        end
      end
      
      describe "but it's the only entry" do
        describe_called_with prerelease: ['rc'] do
          it { is_expected.to be response }
        end
      end # "but it's the only entry"
      
      describe "but there is more than one additional entry" do
        describe_called_with prerelease: ['rc', 0, 1] do
          it { is_expected.to be response }
        end
      end # "but it's the only entry"
      
    end # "when prerelease[0] is 'rc' but [1] is not positive integer"
  end # response: QB::Package::Version
  
end # spec_file
