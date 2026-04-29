require "./spec_helper"

describe Meru::FastqReader do
  it "reads FASTQ sequences" do
    seqs = [] of String
    Meru::FastqReader.new("spec/fixtures/tiny.fastq").each_sequence do |seq|
      seqs << seq.to_s
    end
    seqs.should eq ["ACGTACGT", "ACGTACGA"]
  end

  it "reads FASTQ sequence copies" do
    seqs = [] of String
    Meru::FastqReader.new("spec/fixtures/tiny.fastq").each_sequence_copy do |seq|
      seqs << seq
    end
    seqs.should eq ["ACGTACGT", "ACGTACGA"]
  end
end
