module Meru
  class Histogram
    getter bins : Hash(UInt32, UInt64)

    def initialize(@bins : Hash(UInt32, UInt64))
    end

    def self.from_counts(counts : KmerCounts) : Histogram
      bins = Hash(UInt32, UInt64).new(0_u64)
      counts.each_value do |coverage|
        bins[coverage] += 1_u64
      end
      Histogram.new(bins)
    end

    def singleton_kmers : UInt64
      @bins[1_u32]
    end

    def distinct_kmers : UInt64
      total = 0_u64
      @bins.each_value { |count| total += count }
      total
    end

    def max_coverage : UInt32
      @bins.keys.max? || 0_u32
    end

    def peak_coverage : UInt32
      best_cov = 0_u32
      best_count = 0_u64
      @bins.each do |coverage, count|
        next if coverage < 2_u32
        if count > best_count
          best_cov = coverage
          best_count = count
        end
      end
      best_cov
    end

    def each_bin(min_cov : Int32 = 1, max_cov : Int32? = nil, & : UInt32, UInt64 ->)
      lower = min_cov < 1 ? 1_u32 : min_cov.to_u32
      upper = if max = max_cov
                max.to_u32
              else
                max_coverage
              end

      (lower..upper).each do |cov|
        count = @bins[cov]
        next if count == 0_u64
        yield cov, count
      end
    end

    def write_tsv(path : String, min_cov : Int32 = 1, max_cov : Int32? = nil)
      File.open(path, "w") do |io|
        io.puts "coverage\tcount"
        each_bin(min_cov, max_cov) do |cov, count|
          io.puts "#{cov}\t#{count}"
        end
      end
    end
  end
end
