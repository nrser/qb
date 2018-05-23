describe_spec_file(
  spec_path:        __FILE__,
  module:           QB,
) do
  
  describe_method :testing? do
    describe_called_with() do
      it { is_expected.to be true }
    end # Called With() Description
  end
  
end # Spec File Description
