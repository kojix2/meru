require "./spec_helper"

describe Meru::Counter do
  it "counts k-mers from sequences" do
    counter = Meru::Counter.new(3)
    counter.add_sequence("ACGTACGT")
    counter.total_reads.should eq 1_u64
    counter.total_bases.should eq 8_u64
    counter.valid_kmers.should eq 6_u64
    counter.counts.empty?.should be_false
  end

  it "counts k-mers from IO::Memory sequences" do
    counter = Meru::Counter.new(3)
    counter.add_sequence(IO::Memory.new("ACGTACGT"))
    counter.total_reads.should eq 1_u64
    counter.total_bases.should eq 8_u64
    counter.valid_kmers.should eq 6_u64
    counter.counts.empty?.should be_false
  end
end
