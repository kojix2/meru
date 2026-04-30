module Meru
  module Summary
    extend self

    def write(path : String, config : Config, counter : Counter, hist : Histogram, pairs : PairTable? = nil, signals : Array(Signal)? = nil)
      File.open(path, "w") do |io|
        io.puts "meru summary"
        io.puts
        io.puts "Input:"
        io.puts "  files: #{config.input_paths.join(", ")}"
        io.puts
        io.puts "Parameters:"
        io.puts "  k: #{config.k}"
        io.puts "  threads: #{config.threads}"
        io.puts "  pair min depth: #{config.pair_min_depth}"
        io.puts "  pair max depth: #{config.pair_max_depth || "auto"}"
        io.puts
        io.puts "K-mer count:"
        io.puts "  total reads: #{counter.total_reads}"
        io.puts "  total bases: #{counter.total_bases}"
        io.puts "  valid k-mers: #{counter.valid_kmers}"
        io.puts "  distinct k-mers: #{hist.distinct_kmers}"
        io.puts "  singleton k-mers: #{hist.singleton_kmers}"
        io.puts
        io.puts "Histogram:"
        io.puts "  peak coverage: #{hist.peak_coverage}"
        io.puts "  max depth: #{hist.max_coverage}"
        io.puts "  displayed depth range: #{config.min_depth}..#{config.max_depth || hist.max_coverage}"

        if pair_table = pairs
          io.puts
          io.puts "K-mer pairs:"
          io.puts "  total one-base-different pairs: #{pair_table.total_pairs}"
        end

        if signal_list = signals
          io.puts
          io.puts "Smudge signals:"
          signal_list.each do |sig|
            io.puts "  #{sig.label}: #{sig.strength} (support: #{sig.support})"
          end
          io.puts
          io.puts "Interpretation note:"
          io.puts "  These labels are rough hints based only on minor-ratio bins."
          io.puts "  They are not a replacement for full Smudgeplot / GenomeScope analysis."
        end
      end
    end
  end
end
