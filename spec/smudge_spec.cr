require "./spec_helper"

describe Meru::SmudgeTable do
  it "converts coverage pairs to minor-ratio bins" do
    bins = Hash(Meru::CoveragePair, UInt64).new(0_u64)
    bins[{3_u32, 6_u32}] = 10_u64
    pairs = Meru::PairTable.new(bins)

    smudges = Meru::SmudgeTable.from_pairs(pairs)
    smudges.bins[{3_u32, 9_u32}].should eq 10_u64
  end
end
