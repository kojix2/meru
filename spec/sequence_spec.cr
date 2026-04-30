require "./spec_helper"

describe Meru::SequenceReader do
  it "reads FASTQ sequences" do
    seqs = [] of String
    Meru::SequenceReader.new("spec/fixtures/tiny.fastq").each_sequence do |seq|
      seqs << seq.to_s
    end
    seqs.should eq ["ACGTACGT", "ACGTACGA"]
  end

  it "reads FASTA sequences" do
    seqs = [] of String
    Meru::SequenceReader.new("spec/fixtures/tiny.fasta").each_sequence do |seq|
      seqs << seq.to_s
    end
    seqs.should eq ["ACGTACGT", "ACGTACGA"]
  end

  it "reads FASTQ sequence copies" do
    seqs = [] of String
    Meru::SequenceReader.new("spec/fixtures/tiny.fastq").each_sequence_copy do |seq|
      seqs << seq
    end
    seqs.should eq ["ACGTACGT", "ACGTACGA"]
  end

  it "reads FASTA sequence copies" do
    seqs = [] of String
    Meru::SequenceReader.new("spec/fixtures/tiny.fasta").each_sequence_copy do |seq|
      seqs << seq
    end
    seqs.should eq ["ACGTACGT", "ACGTACGA"]
  end

  it "raises for unsupported input extensions" do
    expect_raises(Meru::SequenceReadError, /unsupported input format/) do
      Meru::SequenceReader.new("spec/fixtures/tiny.txt").each_sequence do |_seq|
      end
    end
  end
end
