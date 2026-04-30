require "./spec_helper"

describe Meru::Config do
  it "defaults the main depth range to start at 2" do
    config = Meru::Config.new

    config.min_depth.should eq 2
    config.effective_pair_min_depth.should eq 2
  end

  it "uses the main depth range for pair extraction by default" do
    config = Meru::Config.new(min_depth: 5, max_depth: 100)

    config.effective_pair_min_depth.should eq 5
    config.effective_pair_max_depth.should eq 100
  end

  it "lets pair-specific depth settings override the main range" do
    config = Meru::Config.new(
      min_depth: 5,
      max_depth: 100,
      pair_min_depth: 8,
      pair_max_depth: 40
    )

    config.effective_pair_min_depth.should eq 8
    config.effective_pair_max_depth.should eq 40
  end
end
