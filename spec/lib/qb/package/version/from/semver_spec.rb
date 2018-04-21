describe_spec_file(
  spec_path: __FILE__,
  module: QB::Package::Version::From,
  method: :semver,
) do
  
  shared_examples :blah do |**attrs|
    it { is_expected.to be_a QB::Package::Version }
    it { is_expected.to have_attributes attrs }
  end
  
  
  describe_called_with '1.2.3.4-pre' do
    include_examples :blah,
      major: 1,
      minor: 2,
      patch: 3,
      revision: [4],
      prerelease: ['pre']
  end # Called With  Description
  
end
