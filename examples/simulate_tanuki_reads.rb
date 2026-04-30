#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require_relative 'tanuki_support'

def parse_args
  options = {
    reads_per_copy: TanukiSupport::DEFAULT_READS_PER_COPY,
    read_length: TanukiSupport::DEFAULT_READ_LENGTH,
    seed: TanukiSupport::DEFAULT_SEED
  }

  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: ruby examples/simulate_tanuki_reads.rb [options]'
    opts.on('--genome PATH', 'Input FASTA.') { |value| options[:genome] = value }
    opts.on('--output PATH', 'Output FASTQ path.') { |value| options[:output] = value }
    opts.on('--reads-per-copy INT', Integer, 'Number of reads to sample from each haploid copy.') do |value|
      options[:reads_per_copy] = value
    end
    opts.on('--read-length INT', Integer, 'Read length.') { |value| options[:read_length] = value }
    opts.on('--seed INT', Integer, 'Random seed.') { |value| options[:seed] = value }
  end

  parser.parse!
  raise OptionParser::MissingArgument, '--genome' unless options[:genome]
  raise OptionParser::MissingArgument, '--output' unless options[:output]

  options
end

def write_fastq(path, reads)
  FileUtils.mkdir_p(File.dirname(path))
  File.open(path, 'w:ascii') do |handle|
    reads.each do |name, sequence|
      handle.puts("@#{name}")
      handle.puts(sequence)
      handle.puts('+')
      handle.puts('I' * sequence.length)
    end
  end
end

def main
  args = parse_args
  rng = Random.new(args[:seed])
  records = TanukiSupport.read_fasta(File.expand_path(args[:genome]))
  raise 'no FASTA records found' if records.empty?

  reads = []

  records.each do |contig_name, sequence|
    max_start = sequence.length - args[:read_length]
    raise 'read length must be <= contig length' if max_start.negative?

    args[:reads_per_copy].times do |read_index|
      start = rng.rand(0..max_start)
      read = sequence[start, args[:read_length]]
      reads << ["#{contig_name}_#{read_index + 1}", read]
    end
  end

  reads.shuffle!(random: rng)

  output_path = File.expand_path(args[:output])
  write_fastq(output_path, reads)

  puts "wrote #{output_path}"
  puts "reads_per_copy: #{args[:reads_per_copy]}"
  puts "total_reads: #{reads.length}"
  puts "read_length: #{args[:read_length]}"
end

main if $PROGRAM_NAME == __FILE__
