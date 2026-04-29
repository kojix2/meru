# frozen_string_literal: true

require "csv"
require "fileutils"

module TanukiSupport
  DEFAULT_SEED = 20_260_429
  DEFAULT_OUTDIR = "examples/out/tanuki"
  DEFAULT_GENOMES_OUTDIR = "#{DEFAULT_OUTDIR}/genomes"
  DEFAULT_GENOME_LENGTH = 3600
  DEFAULT_READS_PER_COPY = 480
  DEFAULT_READ_LENGTH = 90

  SPECIES = {
    "tanuki1" => {
      "ploidy" => 1,
      "haplotypes" => ["A"],
      "expected_note" => "haploid; no heterozygous smudge expected",
    },
    "tanuki2" => {
      "ploidy" => 2,
      "haplotypes" => ["A", "B"],
      "expected_note" => "private SNPs should concentrate near minor ratio 0.50",
    },
    "tanuki4" => {
      "ploidy" => 4,
      "haplotypes" => ["A", "B", "C", "D"],
      "expected_note" => "private SNPs near 0.25 and pair-shared SNPs near 0.50",
    },
    "tanuki20" => {
      "ploidy" => 20,
      "haplotypes" => (["A"] * 19) + ["B"],
      "expected_note" => "one minor haplotype copy; private SNPs should concentrate near 0.05",
    },
  }.freeze

  DISPLAY_SPECIES = ["tanuki2", "tanuki4", "tanuki20"].freeze

  SPECIES_NOTES = {
    "tanuki1" => "ploidy 1, haplotype A only, expected: almost no smudge",
    "tanuki2" => "ploidy 2, haplotypes A+B, expected hotspot near minor ratio 0.50",
    "tanuki4" => "ploidy 4, haplotypes A+B+C+D, expected private SNPs near 0.25 and shared-pair SNPs near 0.50",
    "tanuki20" => "ploidy 20, haplotypes A x19 + B x1, expected hotspot near minor ratio 0.05",
  }.freeze

  VARIANT_GROUPS = [
    ["A_private", ["A"], 12],
    ["B_private", ["B"], 12],
    ["C_private", ["C"], 12],
    ["D_private", ["D"], 12],
    ["AB_shared", ["A", "B"], 8],
    ["AC_shared", ["A", "C"], 8],
    ["BD_shared", ["B", "D"], 8],
    ["CD_shared", ["C", "D"], 8],
  ].freeze

  module_function

  def examples_dir
    __dir__
  end

  def repo_root
    File.expand_path("..", examples_dir)
  end

  def script_path(name)
    File.join(examples_dir, name)
  end

  def fasta_wrap(sequence, width = 80)
    sequence.scan(/.{1,#{width}}/).join("\n")
  end

  def write_fasta(path, records)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, "w:ascii") do |handle|
      records.each do |name, sequence|
        handle.puts(">#{name}")
        handle.puts(fasta_wrap(sequence))
      end
    end
  end

  def read_fasta(path)
    records = []
    name = nil
    chunks = []

    File.foreach(path, chomp: true, encoding: "ascii") do |line|
      next if line.empty?

      if line.start_with?(">")
        records << [name, chunks.join] if name
        name = line[1..]
        chunks = []
      else
        chunks << line
      end
    end

    records << [name, chunks.join] if name
    records
  end

  def write_tsv(path, headers, rows)
    File.open(path, "w:ascii") do |handle|
      csv = CSV.new(handle, col_sep: "\t", write_headers: true, headers:)
      rows.each { |row| csv << headers.map { |header| row.fetch(header) } }
    end
  end

  def read_tsv(path)
    CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
  end
end
