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
    bins[{13_u32, 26_u64}] = 20_u64
    bins[{8_u32, 24_u64}] = 10_u64
    smudges = Meru::SmudgeTable.new(bins)
    io = IO::Memory.new

    Meru::Plot.smudge(smudges, nil, true, io, 40, 12)

    output = io.to_s
    output.should contain("Smudgeplot")
    output.should contain("minor ratio")
    output.should contain("total coverage")
    output.should contain("log10(pair count + 1)")
    output.should contain("AAAB")
  end

  it "renders smudge with linear pair-count labeling when requested" do
    bins = Hash(Meru::SmudgeKey, UInt64).new(0_u64)
    bins[{13_u32, 26_u64}] = 20_u64
    smudges = Meru::SmudgeTable.new(bins)
    io = IO::Memory.new

    Meru::Plot.smudge(smudges, nil, false, io, 40, 12)

    output = io.to_s
    output.should contain("pair count")
    output.should_not contain("log10(pair count + 1)")
  end

  it "doubles max depth for smudge total coverage display" do
    Meru::Plot.smudge_display_max_total_cov(50).should eq 100
    Meru::Plot.smudge_display_max_total_cov(nil).should be_nil
  end

  it "renders higher total coverage above lower total coverage in Unicode smudge plots" do
    bins = Hash(Meru::SmudgeKey, UInt64).new(0_u64)
    bins[{5_u32, 10_u64}] = 1_u64
    bins[{5_u32, 90_u64}] = 100_u64
    smudges = Meru::SmudgeTable.new(bins)
    io = IO::Memory.new

    Meru::Plot.smudge(smudges, 100, true, io, 30, 10)

    lines = io.to_s.lines
    top_idx = lines.index { |line| line.matches?(/^\s*100 │/) }
    bottom_idx = lines.index { |line| line.matches?(/^\s*0 │/) }

    top_idx.should_not be_nil
    bottom_idx.should_not be_nil
    top_idx.not_nil!.should be < bottom_idx.not_nil!
  end
end
