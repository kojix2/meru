module Meru
  alias SmudgeKey = Tuple(UInt32, UInt64) # minor_cov, total_cov

  class SmudgeTable
    getter bins : Hash(SmudgeKey, UInt64)

    def initialize(@bins : Hash(SmudgeKey, UInt64))
    end

    def self.from_pairs(pairs : PairTable) : SmudgeTable
      bins = Hash(SmudgeKey, UInt64).new(0_u64)
      pairs.bins.each do |coverage_pair, count|
        cov_a = coverage_pair[0]
        cov_b = coverage_pair[1]
        minor = cov_a < cov_b ? cov_a : cov_b
        total = cov_a.to_u64 + cov_b.to_u64
        bins[{minor, total}] += count
      end
      SmudgeTable.new(bins)
    end

    def total_count : UInt64
      total = 0_u64
      @bins.each_value { |count| total += count }
      total
    end

    def max_total_coverage : UInt64
      max = 0_u64
      @bins.each_key do |key|
        total = key[1]
        max = total if total > max
      end
      max
    end

    def write_tsv(path : String)
      rows = @bins.to_a.sort_by { |entry| {entry[0][1], entry[0][0]} }
      File.open(path, "w") do |io|
        io.puts "minor_ratio\ttotal_cov\tminor_cov\tcount\tlabel_hint"
        rows.each do |entry|
          key = entry[0]
          count = entry[1]
          minor = key[0]
          total = key[1]
          ratio = minor.to_f / total.to_f
          io.puts "#{format_float(ratio)}\t#{total}\t#{minor}\t#{count}\t#{label_hint(ratio)}"
        end
      end
    end

    def self.format_float(value : Float64) : String
      String.build do |io|
        io << value.round(4)
      end
    end

    private def format_float(value : Float64) : String
      SmudgeTable.format_float(value)
    end

    private def label_hint(ratio : Float64) : String
      if close?(ratio, 0.5, 0.04)
        "AB_or_AABB"
      elsif close?(ratio, 1.0 / 3.0, 0.04)
        "AAB"
      elsif close?(ratio, 0.25, 0.035)
        "AAAB"
      elsif close?(ratio, 0.2, 0.03)
        "AAAAB"
      else
        "."
      end
    end

    private def close?(a : Float64, b : Float64, tol : Float64) : Bool
      (a - b).abs <= tol
    end
  end
end
