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
          expect{ subject }.to raise_error TypeError, /failed type check/
        end
      end # called with ''
      
      # describe_called_with '' do
      #   it do
      #     is_expected.to eq "blah"
      #   end
      # end # called with ''
    end
    
  end # section rejects
  # ************************************************************************
end # QB::Package::Version
