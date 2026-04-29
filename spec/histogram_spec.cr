require "./spec_helper"

describe Meru::Histogram do
  it "builds coverage histogram" do
    counts = Meru::KmerCounts.new(0_u32)
    counts[1_u64] = 1_u32
    counts[2_u64] = 2_u32
    counts[3_u64] = 2_u32

    hist = Meru::Histogram.from_counts(counts)
    hist.bins[1_u32].should eq 1_u64
    hist.bins[2_u32].should eq 2_u64
    hist.singleton_kmers.should eq 1_u64
    hist.peak_coverage.should eq 2_u32
  end
end
