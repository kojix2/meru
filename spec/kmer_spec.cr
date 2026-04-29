require "./spec_helper"

describe Meru::Kmer do
  it "enumerates canonical k-mers" do
    kmers = [] of UInt64
    Meru::Kmer.each_canonical("ACGT", 3) { |k| kmers << k }
    kmers.size.should eq 2
  end

  it "matches the expected canonical windows" do
    kmers = [] of UInt64
    Meru::Kmer.each_canonical("ACGT", 3) { |k| kmers << k }
    kmers.should eq [6_u64, 6_u64]
  end

  it "skips k-mers containing N" do
    kmers = [] of UInt64
    Meru::Kmer.each_canonical("ACNGT", 3) { |k| kmers << k }
    kmers.empty?.should be_true
  end

  it "resets the rolling window after invalid bases" do
    kmers = [] of UInt64
    Meru::Kmer.each_canonical("ACGTNACGT", 3) { |k| kmers << k }
    kmers.should eq [6_u64, 6_u64, 6_u64, 6_u64]
  end

  it "handles k = 32" do
    seq = "A" * 32
    kmers = [] of UInt64
    Meru::Kmer.each_canonical(seq, 32) { |k| kmers << k }
    kmers.should eq [0_u64]
  end

  it "rejects k greater than 32" do
    expect_raises(ArgumentError) do
      Meru::Kmer.validate_k!(33)
    end
  end
end
