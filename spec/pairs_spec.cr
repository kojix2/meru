require "./spec_helper"

describe Meru::PairExtractor do
  it "uses depth 2 as the default minimum depth" do
    counts = Meru::KmerCounts.new(0_u32)
    a = 0b0000_u64 # AA, canonical
    b = 0b0001_u64 # AC, canonical
    counts[a] = 1_u32
    counts[b] = 2_u32

    pairs = Meru::PairExtractor.extract(counts, 2)
    pairs.total_pairs.should eq 0_u64
  end

  it "matches single-threaded and parallel extraction" do
    counts = Meru::KmerCounts.new(0_u32)
    %w[AAA AAC AAG AAT ACC ACT AGT CCC].each_with_index do |seq, index|
      kmer = 0_u64
      Meru::Kmer.each_canonical(seq, 3) { |value| kmer = value }
      counts[kmer] = (index + 2).to_u32
    end

    pairs_single = Meru::PairExtractor.extract(counts, 3, 2, nil, 1)
    pairs_parallel = Meru::PairExtractor.extract(counts, 3, 2, nil, 4)

    pairs_parallel.bins.should eq(pairs_single.bins)
  end

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

  it "skips out-of-range source and neighbor depths before recording pairs" do
    counts = Meru::KmerCounts.new(0_u32)
    aa = 0b0000_u64
    ac = 0b0001_u64
    ag = 0b0010_u64
    counts[aa] = 1_u32
    counts[ac] = 5_u32
    counts[ag] = 10_u32

    pairs = Meru::PairExtractor.extract(counts, 2, 5, 6, 2)

    pairs.empty?.should be_true
  end
end
