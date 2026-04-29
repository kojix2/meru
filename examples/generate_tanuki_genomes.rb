#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "optparse"
require_relative "tanuki_support"

def parse_args
  options = {
    outdir: TanukiSupport::DEFAULT_GENOMES_OUTDIR,
    genome_length: TanukiSupport::DEFAULT_GENOME_LENGTH,
    seed: TanukiSupport::DEFAULT_SEED,
  }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby examples/generate_tanuki_genomes.rb [options]"
    opts.on("--outdir PATH", "Directory for generated FASTA files.") { |value| options[:outdir] = value }
    opts.on("--genome-length INT", Integer, "Length of the monoploid tanuki chromosome.") do |value|
      options[:genome_length] = value
    end
    opts.on("--seed INT", Integer, "Random seed.") { |value| options[:seed] = value }
  end

  parser.parse!
  options
end

def make_reference(length, rng)
  Array.new(length) { "ACGT"[rng.rand(4)] }.join
end

def mutate_base(base)
  {
    "A" => "C",
    "C" => "G",
    "G" => "T",
    "T" => "A",
  }.fetch(base)
end

def spaced_variant_positions(length, count)
  return [] if count < 1

  margin = 100
  usable = length - (2 * margin)
  raise "genome too short for the requested number of spaced variants" if usable <= count * 20

  step = usable / count
  Array.new(count) { |index| margin + (index * step) }
end

def build_haplotypes(reference, positions)
  haplotype_chars = {
    "A" => reference.chars,
    "B" => reference.chars,
    "C" => reference.chars,
    "D" => reference.chars,
  }
  catalog_rows = []
  position_index = 0

  TanukiSupport::VARIANT_GROUPS.each do |group_name, haplotypes, variant_count|
    variant_count.times do
      pos = positions.fetch(position_index)
      position_index += 1
      ref_base = reference[pos]
      alt_base = mutate_base(ref_base)

      haplotypes.each do |haplotype|
        haplotype_chars.fetch(haplotype)[pos] = alt_base
      end

      catalog_rows << {
        "position_1based" => (pos + 1).to_s,
        "group" => group_name,
        "haplotypes" => haplotypes.join("+"),
        "ref" => ref_base,
        "alt" => alt_base,
      }
    end
  end

  haplotypes = haplotype_chars.transform_values(&:join)
  [haplotypes, catalog_rows]
end

def main
  args = parse_args
  rng = Random.new(args[:seed])
  outdir = File.expand_path(args[:outdir])
  FileUtils.mkdir_p(outdir)

  reference = make_reference(args[:genome_length], rng)
  total_variants = TanukiSupport::VARIANT_GROUPS.sum { |_name, _haplotypes, count| count }
  positions = spaced_variant_positions(args[:genome_length], total_variants)
  haplotypes, catalog_rows = build_haplotypes(reference, positions)

  TanukiSupport.write_fasta(File.join(outdir, "tanuki_ancestor.fa"), [["tanuki_ancestor_chr1", reference]])
  TanukiSupport.write_fasta(
    File.join(outdir, "tanuki_haplotypes.fa"),
    haplotypes.map { |name, sequence| ["tanuki#{name}_chr1", sequence] }
  )

  manifest_rows = []

  TanukiSupport::SPECIES.each do |species, config|
    records = []
    haplotype_counts = Hash.new(0)
    config.fetch("haplotypes").each { |haplotype_name| haplotype_counts[haplotype_name] += 1 }

    haplotype_counts.sort.each do |haplotype_name, copy_count|
      copy_count.times do |copy_index|
        records << [
          "#{species}_#{haplotype_name}_copy#{copy_index + 1}",
          haplotypes.fetch(haplotype_name),
        ]
      end
    end

    TanukiSupport.write_fasta(File.join(outdir, "#{species}.fa"), records)
    manifest_rows << {
      "species" => species,
      "ploidy" => config.fetch("ploidy").to_s,
      "haplotypes" => config.fetch("haplotypes").join("+"),
      "expected_note" => config.fetch("expected_note"),
    }
  end

  TanukiSupport.write_tsv(
    File.join(outdir, "tanuki_manifest.tsv"),
    ["species", "ploidy", "haplotypes", "expected_note"],
    manifest_rows
  )
  TanukiSupport.write_tsv(
    File.join(outdir, "tanuki_variant_catalog.tsv"),
    ["position_1based", "group", "haplotypes", "ref", "alt"],
    catalog_rows
  )

  puts "wrote #{outdir}"
  puts "species: #{TanukiSupport::SPECIES.keys.join(', ')}"
  puts "variant_positions: #{positions.map { |pos| pos + 1 }.join(',')}"
end

main if $PROGRAM_NAME == __FILE__
