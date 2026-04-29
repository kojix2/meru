require "./spec_helper"

describe Meru::PairExtractor do
  it "aggregates one-base-different k-mer pairs by coverage" do
    counts = Meru::KmerCounts.new(0_u32)
    a = 0b0000_u64 # AA, canonical
    b = 0b0001_u64 # AC, canonical
    counts[a] = 3_u32
    counts[b] = 5_u32

    pairs = Meru::PairExtractor.extract(counts, 2, 1, nil)
    pairs.bins[{3_u32, 5_u32}].should eq 1_u64
  end

  it "does not double count canonical neighbors produced by multiple mutations" do
    counts = Meru::KmerCounts.new(0_u32)

    aat = 0_u64
    act = 0_u64
    Meru::Kmer.each_canonical("AAT", 3) { |kmer| aat = kmer }
    Meru::Kmer.each_canonical("ACT", 3) { |kmer| act = kmer }

    counts[aat] = 4_u32
    counts[act] = 7_u32

    pairs = Meru::PairExtractor.extract(counts, 3, 1, nil)
    pairs.bins[{4_u32, 7_u32}].should eq 1_u64
    pairs.total_pairs.should eq 1_u64
  end
end
