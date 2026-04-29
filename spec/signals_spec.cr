require "./spec_helper"

describe Meru::Signals do
  it "summarizes rough smudge labels" do
    bins = Hash(Meru::SmudgeKey, UInt64).new(0_u64)
    bins[{5_u32, 10_u32}] = 100_u64
    smudges = Meru::SmudgeTable.new(bins)

    signals = Meru::Signals.summarize(smudges, 10_u32)
    ab = signals.find! { |sig| sig.label == "AB" }
    ab.support.should eq 100_u64
    ab.strength.should eq "strong"
  end
end
