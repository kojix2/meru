require "./spec_helper"

describe Meru::Plot do
  it "renders histogram with UnicodePlot" do
    counts = Meru::KmerCounts.new(0_u32)
    counts[1_u64] = 2_u32
    counts[2_u64] = 4_u32
    counts[3_u64] = 4_u32
    hist = Meru::Histogram.from_counts(counts)
    io = IO::Memory.new

    Meru::Plot.histogram(hist, 1, nil, false, io, 40, 10)

    output = io.to_s
    output.should contain("k-mer coverage histogram")
    output.should contain("distinct k-mers")
    output.should contain("coverage")
  end

  it "renders log histogram label" do
    counts = Meru::KmerCounts.new(0_u32)
    counts[1_u64] = 10_u32
    hist = Meru::Histogram.from_counts(counts)
    io = IO::Memory.new

    Meru::Plot.histogram(hist, 1, nil, true, io, 40, 10)

    io.to_s.should contain("log10(distinct k-mers + 1)")
  end

  it "renders smudge as a heatmap-style plot" do
    bins = Hash(Meru::SmudgeKey, UInt64).new(0_u64)
    bins[{13_u32, 26_u32}] = 20_u64
    bins[{8_u32, 24_u32}] = 10_u64
    smudges = Meru::SmudgeTable.new(bins)
    io = IO::Memory.new

    Meru::Plot.smudge(smudges, nil, io, 40, 12)

    output = io.to_s
    output.should contain("Smudgeplot")
    output.should contain("minor ratio")
    output.should contain("total coverage")
    output.should contain("AAAB")
  end

  it "doubles max depth for smudge total coverage display" do
    Meru::Plot.smudge_display_max_total_cov(50).should eq 100
    Meru::Plot.smudge_display_max_total_cov(nil).should be_nil
  end
end
