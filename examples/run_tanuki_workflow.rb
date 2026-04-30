#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "open3"
require "optparse"
require "pty"
require_relative "tanuki_support"

ANSI_RESET = "\e[0m"
ANSI_BOLD = "\e[1m"
ANSI_DIM = "\e[2m"
ANSI_CYAN = "\e[36m"
ANSI_YELLOW = "\e[33m"
ANSI_GREEN = "\e[32m"
ANSI_MAGENTA = "\e[35m"
ANSI_BLUE = "\e[34m"

CompletedCommand = Struct.new(:stdout, :stderr, :exit_status, keyword_init: true)

def use_color?
  $stdout.tty? && !ENV.key?("NO_COLOR")
end

def style(text, *codes)
  return text unless use_color?

  "#{codes.join}#{text}#{ANSI_RESET}"
end

def heavy_rule(label = nil, width = 88)
  return "━" * width unless label

  core = " #{label} "
  side = [(width - core.length) / 2, 0].max
  line = ("━" * side) + core + ("━" * side)
  line.length > width ? line[0, width] : line.ljust(width, "━")
end

def parse_args
  options = {
    outdir: TanukiSupport::DEFAULT_OUTDIR,
    meru: "bin/meru",
    k: 21,
    reads_per_copy: TanukiSupport::DEFAULT_READS_PER_COPY,
    read_length: TanukiSupport::DEFAULT_READ_LENGTH,
    seed: TanukiSupport::DEFAULT_SEED,
    width: 40,
    height: 30,
  }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby examples/run_tanuki_workflow.rb [options]"
    opts.on("--outdir PATH", "Root directory for genomes, reads, and meru outputs.") { |value| options[:outdir] = value }
    opts.on("--meru PATH", "Path to the meru executable.") { |value| options[:meru] = value }
    opts.on("--k INT", Integer, "k-mer size passed to meru.") { |value| options[:k] = value }
    opts.on("--reads-per-copy INT", Integer, "Number of reads to sample from each haploid copy.") do |value|
      options[:reads_per_copy] = value
    end
    opts.on("--read-length INT", Integer, "Read length.") { |value| options[:read_length] = value }
    opts.on("--seed INT", Integer, "Base random seed.") { |value| options[:seed] = value }
    opts.on("--width INT", Integer, "Plot width passed to meru.") { |value| options[:width] = value }
    opts.on("--height INT", Integer, "Plot height passed to meru.") { |value| options[:height] = value }
  end

  parser.parse!
  options
end

def run_command(cmd, chdir:)
  stdout, stderr, status = Open3.capture3(*cmd, chdir:)
  return CompletedCommand.new(stdout:, stderr:, exit_status: status.exitstatus) if status.success?

  message = ["command failed: #{cmd.join(' ')}", stdout.strip, stderr.strip].reject(&:empty?).join("\n")
  raise message
end

def run_meru_command(cmd, chdir:, terminal_path:)
  unless $stdout.tty?
    result = run_command(cmd, chdir:)
    File.write(terminal_path, result.stdout, mode: "w:utf-8")
    return result
  end

  stdout_text = +""
  stderr_text = +""
  exit_status = nil

  PTY.spawn(*cmd, chdir:) do |reader, writer, pid|
    writer.close

    begin
      loop { stdout_text << reader.readpartial(4096).force_encoding("UTF-8") }
    rescue EOFError, Errno::EIO
      nil
    ensure
      _pid, status = Process.wait2(pid)
      exit_status = status.exitstatus
      reader.close unless reader.closed?
    end
  end

  File.write(terminal_path, stdout_text, mode: "w:utf-8")
  if exit_status != 0
    message = ["command failed: #{cmd.join(' ')}", stdout_text.strip, stderr_text.strip].reject(&:empty?).join("\n")
    raise message
  end

  CompletedCommand.new(stdout: stdout_text, stderr: stderr_text, exit_status:)
end

def read_summary_field(path, label)
  prefix = "  #{label}: "
  File.foreach(path, encoding: "utf-8") do |line|
    return line.delete_prefix(prefix).strip if line.start_with?(prefix)
  end
  "."
end

def dominant_smudge(path)
  rows = TanukiSupport.read_tsv(path)
  return ["none", "0"] if rows.empty?

  best = rows.max_by { |row| row.fetch("count").to_i }
  [best.fetch("minor_ratio"), best.fetch("count")]
end

def extract_smudge_section(text)
  marker = "Smudgeplot"
  index = text.index(marker)
  index ? text[index..].strip : text.strip
end

def write_report(outdir, rows, base_seed)
  report_path = File.join(outdir, "README.txt")
  File.open(report_path, "w:utf-8") do |handle|
    handle.puts("Tanuki lineage demo for meru")
    handle.puts
    handle.puts("Seeds:")
    handle.puts("  base seed: #{base_seed}")
    TanukiSupport::SPECIES.each_key.with_index do |species, index|
      handle.puts("  #{species} read seed: #{base_seed + index}")
    end
    handle.puts
    handle.puts("Fictional background:")
    handle.puts("  tanuki1 is haploid and carries only haplotype A.")
    handle.puts("  tanuki2 is diploid and carries A+B.")
    handle.puts("  tanuki4 is tetraploid and carries four related haplotypes: A+B+C+D.")
    handle.puts("  tanuki8 is polyploid and carries A repeated 7 times plus one B copy.")
    handle.puts
    handle.puts("Interpretation guide:")
    handle.puts("  tanuki1 should show almost no smudge because there is no heterozygous partner haplotype.")
    handle.puts("  tanuki2 should concentrate near minor ratio 0.50.")
    handle.puts("  tanuki4 should show a mixed pattern: private SNPs near 0.25 and pair-shared SNPs near 0.50.")
    handle.puts("  tanuki8 should concentrate near minor ratio 0.125 and higher total coverage.")
    handle.puts
    handle.puts("Observed summaries:")
    rows.each do |row|
      handle.puts(
        "  #{row.fetch('species')}: peak_cov=#{row.fetch('peak_cov')}  " \
        "dominant_minor_ratio=#{row.fetch('minor_ratio')}  " \
        "AB=#{row.fetch('AB')}  AAB=#{row.fetch('AAB')}  " \
        "AAAB=#{row.fetch('AAAB')}  AABB=#{row.fetch('AABB')}"
      )
    end
    handle.puts
    handle.puts("Suggested inspection order:")
    handle.puts("  1. meru/*_terminal.txt for UnicodePlot histogram + smudge heatmap")
    handle.puts("  2. meru/*.signals.tsv for rough labels")
    handle.puts("  3. meru/*.smudge.tsv for exact minor_ratio / total_cov bins")
  end
end

def print_intro(base_seed)
  puts style("Tanuki smudge demo for meru", ANSI_BOLD, ANSI_CYAN)
  puts
  puts "#{style('  tanuki2', ANSI_BOLD, ANSI_GREEN)} = ploidy 2"
  puts "#{style('  tanuki4', ANSI_BOLD, ANSI_GREEN)} = ploidy 4"
  puts "#{style('  tanuki8', ANSI_BOLD, ANSI_GREEN)} = ploidy 8"
  puts
  puts style("base seed: #{base_seed}", ANSI_DIM)
  puts
  puts style("Each tanuki shares the same small base genome,", ANSI_DIM)
  puts style("but their haplotype composition changes across the lineage.", ANSI_DIM)
  puts style("Below are the three smudge heatmaps that matter most for visual comparison.", ANSI_DIM)
  puts
end

def print_species_header(species)
  puts style(heavy_rule(species), ANSI_BLUE, ANSI_BOLD)
  puts style("  #{TanukiSupport::SPECIES_NOTES.fetch(species)}", ANSI_YELLOW)
  puts
end

def print_species_summary(row)
  puts style("  Summary", ANSI_BOLD, ANSI_MAGENTA)
  puts(
    "  #{style('peak_cov', ANSI_DIM)}=#{row.fetch('peak_cov')}  " \
    "#{style('minor_ratio', ANSI_DIM)}=#{row.fetch('minor_ratio')}  " \
    "#{style('AB', ANSI_DIM)}=#{row.fetch('AB')}  " \
    "#{style('AAB', ANSI_DIM)}=#{row.fetch('AAB')}  " \
    "#{style('AAAB', ANSI_DIM)}=#{row.fetch('AAAB')}  " \
    "#{style('AABB', ANSI_DIM)}=#{row.fetch('AABB')}"
  )
  puts
end

def print_smudge_block(result)
  section = extract_smudge_section(result.stdout)
  puts(section.empty? ? "(no smudge section captured)" : section)
  puts
end

def print_comparison_summary(rows, outdir)
  puts style(heavy_rule("comparison summary"), ANSI_CYAN, ANSI_BOLD)
  rows.each do |row|
    puts format(
      "%<species>s  %<peak>s=%<peak_cov>4s  %<minor>s=%<minor_ratio>6s  %<ab>s=%<ab_value>8s  %<aab>s=%<aab_value>8s  %<aaab>s=%<aaab_value>8s  %<aabb>s=%<aabb_value>8s",
      species: style(row.fetch("species"), ANSI_BOLD, ANSI_GREEN).ljust(8),
      peak: style("peak_cov", ANSI_DIM),
      peak_cov: row.fetch("peak_cov"),
      minor: style("minor_ratio", ANSI_DIM),
      minor_ratio: row.fetch("minor_ratio"),
      ab: style("AB", ANSI_DIM),
      ab_value: row.fetch("AB"),
      aab: style("AAB", ANSI_DIM),
      aab_value: row.fetch("AAB"),
      aaab: style("AAAB", ANSI_DIM),
      aaab_value: row.fetch("AAAB"),
      aabb: style("AABB", ANSI_DIM),
      aabb_value: row.fetch("AABB")
    )
  end
  puts
  puts "#{style('saved report', ANSI_DIM)}: #{File.join(outdir, 'README.txt')}"
  puts "#{style('saved plots', ANSI_DIM)}:  #{File.join(outdir, 'meru')}"
end

def build_meru_cmd(args, read_path, prefix, no_plot: false)
  cmd = [
    args[:meru],
    read_path,
    "-k", args[:k].to_s,
    "-o", prefix,
    "--log-hist",
    "--plot-width", args[:width].to_s,
    "--plot-height", args[:height].to_s,
  ]
  cmd << "--no-plot" if no_plot
  cmd
end

def build_species_row(species, meru_dir)
  signals = TanukiSupport.read_tsv(File.join(meru_dir, "#{species}.signals.tsv")).each_with_object({}) do |row, hash|
    hash[row.fetch("label")] = row.fetch("strength")
  end
  minor_ratio, = dominant_smudge(File.join(meru_dir, "#{species}.smudge.tsv"))
  {
    "species" => species,
    "peak_cov" => read_summary_field(File.join(meru_dir, "#{species}.summary.txt"), "peak coverage"),
    "minor_ratio" => minor_ratio,
    "AB" => signals.fetch("AB", "."),
    "AAB" => signals.fetch("AAB", "."),
    "AAAB" => signals.fetch("AAAB", "."),
    "AABB" => signals.fetch("AABB", "."),
  }
end

def main
  args = parse_args
  repo_root = TanukiSupport.repo_root
  outdir = File.expand_path(args[:outdir], repo_root)
  genomes_dir = File.join(outdir, "genomes")
  reads_dir = File.join(outdir, "reads")
  meru_dir = File.join(outdir, "meru")
  [genomes_dir, reads_dir, meru_dir].each { |dir| FileUtils.mkdir_p(dir) }

  print_intro(args[:seed])

  run_command(
    ["ruby", TanukiSupport.script_path("generate_tanuki_genomes.rb"), "--outdir", genomes_dir, "--seed", args[:seed].to_s],
    chdir: repo_root
  )

  report_rows = []

  TanukiSupport::SPECIES.each_key.with_index do |species, index|
    genome_path = File.join(genomes_dir, "#{species}.fa")
    read_path = File.join(reads_dir, "#{species}.fastq")
    run_command(
      [
        "ruby",
        TanukiSupport.script_path("simulate_tanuki_reads.rb"),
        "--genome", genome_path,
        "--output", read_path,
        "--reads-per-copy", args[:reads_per_copy].to_s,
        "--read-length", args[:read_length].to_s,
        "--seed", (args[:seed] + index).to_s,
      ],
      chdir: repo_root
    )
  end

  TanukiSupport::DISPLAY_SPECIES.each do |species|
    read_path = File.join(reads_dir, "#{species}.fastq")
    prefix = File.join(meru_dir, species)
    meru_cmd = build_meru_cmd(args, read_path, prefix)
    print_species_header(species)
    result = run_meru_command(meru_cmd, chdir: repo_root, terminal_path: File.join(meru_dir, "#{species}_terminal.txt"))
    print_smudge_block(result)
    print_species_summary(build_species_row(species, meru_dir))
  end

  (TanukiSupport::SPECIES.keys - TanukiSupport::DISPLAY_SPECIES).each do |species|
    read_path = File.join(reads_dir, "#{species}.fastq")
    prefix = File.join(meru_dir, species)
    meru_cmd = build_meru_cmd(args, read_path, prefix, no_plot: true)
    run_command(meru_cmd, chdir: repo_root)
  end

  TanukiSupport::SPECIES.each_key do |species|
    report_rows << build_species_row(species, meru_dir)
  end

  puts style("tanuki1 is omitted from the main heatmap section because it is haploid and usually has no smudge.", ANSI_DIM)
  puts
  write_report(outdir, report_rows, args[:seed])
  print_comparison_summary(report_rows, outdir)
end

main if $PROGRAM_NAME == __FILE__
