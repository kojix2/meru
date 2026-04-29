module Meru
  module CLI
    extend self

    def run(argv : Array(String)) : Nil
      config = Config.new
      show_help = false
      show_version = false

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: meru [options] READS..."

        opts.on("-k INT", "--kmer=INT", "k-mer length (default: 21, max: 32)") do |v|
          config.k = v.to_i
        end

        opts.on("-o PREFIX", "--output=PREFIX", "output prefix (default: meru)") do |v|
          config.output_prefix = v
        end

        opts.on("-t INT", "--threads=INT", "number of worker fibers (default: 1)") do |v|
          config.threads = v.to_i
        end

        opts.on("--min-cov=INT", "minimum coverage shown in histogram (default: 1)") do |v|
          config.min_cov = v.to_i
        end

        opts.on("--max-cov=INT", "maximum coverage shown in histogram and smudge plot") do |v|
          config.max_cov = v.to_i
        end

        opts.on("--pair-min-cov=INT", "minimum k-mer coverage used for pair extraction (default: 2)") do |v|
          config.pair_min_cov = v.to_i
        end

        opts.on("--pair-max-cov=INT", "maximum k-mer coverage used for pair extraction") do |v|
          config.pair_max_cov = v.to_i
        end

        opts.on("--hist-only", "only count k-mers and write histogram/summary") do
          config.hist_only = true
        end

        opts.on("--log-hist", "plot histogram using log10(count + 1) on the y-axis") do
          config.log_hist = true
        end

        opts.on("--no-plot", "do not print terminal plots") do
          config.plot = false
        end

        opts.on("--version", "show version") do
          show_version = true
        end

        opts.on("-h", "--help", "show this help") do
          show_help = true
        end
      end

      begin
        parser.parse(argv)
      rescue ex : OptionParser::Exception
        STDERR.puts "error: #{ex.message}"
        STDERR.puts parser
        exit 1
      end

      if show_version
        puts "meru #{VERSION}"
        return
      end

      if show_help
        puts parser
        return
      end

      config.input_paths = argv.dup
      validate_config!(config)

      counter = Counter.count_files_parallel(config.input_paths, config.k, config.threads)
      hist = Histogram.from_counts(counter.counts)

      hist_path = "#{config.output_prefix}.kmer_hist.tsv"
      summary_path = "#{config.output_prefix}.summary.txt"

      hist.write_tsv(hist_path, config.min_cov, config.max_cov)

      pairs = nil.as(PairTable?)
      smudges = nil.as(SmudgeTable?)
      signals = nil.as(Array(Signal)?)

      unless config.hist_only?
        pairs_local = PairExtractor.extract(counter.counts, config.k, config.pair_min_cov, config.pair_max_cov)
        pairs = pairs_local
        pairs_path = "#{config.output_prefix}.pairs.tsv"
        pairs_local.write_tsv(pairs_path)
        STDERR.puts "wrote #{pairs_path}"

        smudges_local = SmudgeTable.from_pairs(pairs_local)
        smudges = smudges_local
        smudge_path = "#{config.output_prefix}.smudge.tsv"
        smudges_local.write_tsv(smudge_path)
        STDERR.puts "wrote #{smudge_path}"

        signals_local = Signals.summarize(smudges_local, hist.peak_coverage)
        signals = signals_local
        signals_path = "#{config.output_prefix}.signals.tsv"
        Signals.write_tsv(signals_path, signals_local)
        STDERR.puts "wrote #{signals_path}"
      end

      Summary.write(summary_path, config, counter, hist, pairs, signals)

      if config.plot?
        Plot.histogram(hist, config.min_cov, config.max_cov, config.log_hist?)
        unless config.hist_only?
          puts
          if smudges_local = smudges
            Plot.smudge(smudges_local, config.max_cov)
          end
        end
      end

      STDERR.puts "wrote #{hist_path}"
      STDERR.puts "wrote #{summary_path}"
    rescue ex : ArgumentError | FastqError | File::Error
      STDERR.puts "error: #{ex.message}"
      exit 1
    end

    private def validate_config!(config : Config)
      raise ArgumentError.new("no input FASTQ files given") if config.input_paths.empty?
      Kmer.validate_k!(config.k)
      raise ArgumentError.new("threads must be >= 1") if config.threads < 1
      raise ArgumentError.new("min coverage must be >= 1") if config.min_cov < 1
      if max_cov = config.max_cov
        raise ArgumentError.new("max coverage must be >= min coverage") if max_cov < config.min_cov
      end
      raise ArgumentError.new("pair min coverage must be >= 1") if config.pair_min_cov < 1
      if pair_max = config.pair_max_cov
        raise ArgumentError.new("pair max coverage must be >= pair min coverage") if pair_max < config.pair_min_cov
      end
      config.input_paths.each do |path|
        raise ArgumentError.new("input file not found: #{path}") unless File.exists?(path)
      end
    end
  end
end
