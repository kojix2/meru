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

  it "raises worker exceptions instead of waiting forever in parallel counting" do
    expect_raises(ArgumentError, "k must be between 1 and 32") do
      Meru::Counter.count_files_parallel([] of String, 0, 2)
    end
  end

  it "produces the same counts across parallel chunk sizes" do
    paths = [File.expand_path("fixtures/tiny.fastq", __DIR__)]

    chunk1 = Meru::Counter.count_files_parallel(paths, 3, 2, 1)
    chunk10 = Meru::Counter.count_files_parallel(paths, 3, 2, 10)

    chunk1.counts.should eq(chunk10.counts)
    chunk1.total_reads.should eq(chunk10.total_reads)
    chunk1.valid_kmers.should eq(chunk10.valid_kmers)
  end
end
