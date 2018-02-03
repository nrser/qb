describe_spec_file(
  spec_path: __FILE__,
  class: QB::Role,
  method: :matches,
) do
  # Role patterns that we want to "just work" with normal QB setup
  describe "particular test cases" do
    {
      'git/repo'  => 'qb/git/repo',
      'role/qb'   =>  'qb/role/qb',
    }.each do |pattern, name|
      describe "QB::Role.matches #{ pattern.inspect }" do
        subject { QB::Role.matches( pattern ).map( &:name ) }
        
        it "should match only `#{ name }` role" do
          expect( subject ).to be_a( Array ).and have_attributes length: 1
          expect( subject.first ).to eq name
        end
      end
    end # each
  end # "particular test cases"
end
