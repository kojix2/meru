module Meru
  struct Signal
    getter label : String
    getter support : UInt64
    getter strength : String

    def initialize(@label : String, @support : UInt64, @strength : String)
    end
  end

  module Signals
    extend self

    LABELS = ["AB", "AAB", "AAAB", "AABB"]

    def summarize(smudges : SmudgeTable, peak_coverage : UInt32) : Array(Signal)
      support = Hash(String, UInt64).new(0_u64)
      LABELS.each { |label| support[label] = 0_u64 }

      smudges.bins.each do |key, count|
        minor = key[0]
        total = key[1]
        ratio = minor.to_f / total.to_f
        label = classify(ratio, total, peak_coverage)
        support[label] += count if label
      end

      max_support = support.values.max? || 0_u64
      LABELS.map do |label|
        Signal.new(label, support[label], strength(support[label], max_support))
      end
    end

    def write_tsv(path : String, signals : Array(Signal))
      File.open(path, "w") do |io|
        io.puts "label\tsupport\tstrength"
        signals.each do |sig|
          io.puts "#{sig.label}\t#{sig.support}\t#{sig.strength}"
        end
      end
    end

    private def classify(ratio : Float64, total_cov : UInt32, peak_coverage : UInt32) : String?
      if close?(ratio, 1.0 / 3.0, 0.04)
        "AAB"
      elsif close?(ratio, 0.25, 0.035)
        "AAAB"
      elsif close?(ratio, 0.5, 0.04)
        if peak_coverage > 0 && total_cov > (peak_coverage.to_f * 1.5).round.to_u32
          "AABB"
        else
          "AB"
        end
      end
    end

    private def strength(value : UInt64, max_value : UInt64) : String
      return "none" if value == 0_u64 || max_value == 0_u64
      frac = value.to_f / max_value.to_f
      if frac >= 0.5
        "strong"
      elsif frac >= 0.2
        "moderate"
      else
        "weak"
      end
    end

    private def close?(a : Float64, b : Float64, tol : Float64) : Bool
      (a - b).abs <= tol
    end
  end
end
