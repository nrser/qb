require "spec_helper"

RSpec.describe TestGem do
  it "has a version number" do
    expect(TestGem::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
