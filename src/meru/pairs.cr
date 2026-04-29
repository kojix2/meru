module Meru
  alias CoveragePair = Tuple(UInt32, UInt32)

  class PairTable
    getter bins : Hash(CoveragePair, UInt64)

    def initialize(@bins : Hash(CoveragePair, UInt64))
    end

    def total_pairs : UInt64
      total = 0_u64
      @bins.each_value { |count| total += count }
      total
    end

    def empty? : Bool
      @bins.empty?
    end

    def write_tsv(path : String)
      rows = @bins.to_a.sort_by { |entry| {entry[0][0], entry[0][1]} }
      File.open(path, "w") do |io|
        io.puts "cov_a\tcov_b\tcount"
        rows.each do |entry|
          key = entry[0]
          count = entry[1]
          io.puts "#{key[0]}\t#{key[1]}\t#{count}"
        end
      end
    end
  end

  module PairExtractor
    extend self

    def extract(counts : KmerCounts, k : Int32, min_cov : Int32 = 2, max_cov : Int32? = nil) : PairTable
      Kmer.validate_k!(k)
      raise ArgumentError.new("pair min coverage must be >= 1") if min_cov < 1
      if max = max_cov
        raise ArgumentError.new("pair max coverage must be >= pair min coverage") if max < min_cov
      end

      bins = Hash(CoveragePair, UInt64).new(0_u64)
      min_cov_u = min_cov.to_u32
      max_cov_u = max_cov.try(&.to_u32) || UInt32::MAX
      seen_neighbors = Array(UInt64).new(3 * k)

      counts.each do |kmer, cov1|
        next unless coverage_allowed?(cov1, min_cov_u, max_cov_u)

        seen_neighbors.clear
        each_unique_one_base_neighbor(kmer, k, seen_neighbors) do |neighbor|
          add_pair_if_valid(bins, counts, kmer, cov1, neighbor, min_cov_u, max_cov_u)
        end
      end

      PairTable.new(bins)
    end

    private def coverage_allowed?(cov : UInt32, min_cov : UInt32, max_cov : UInt32) : Bool
      cov >= min_cov && cov <= max_cov
    end

    private def add_pair_if_valid(
      bins : Hash(CoveragePair, UInt64),
      counts : KmerCounts,
      kmer : UInt64,
      cov1 : UInt32,
      neighbor : UInt64,
      min_cov_u : UInt32,
      max_cov_u : UInt32,
    ) : Nil
      return if neighbor == kmer
      return unless kmer < neighbor
      cov2 = counts[neighbor]?
      return unless cov2
      return unless coverage_allowed?(cov2, min_cov_u, max_cov_u)

      ca = cov1 < cov2 ? cov1 : cov2
      cb = cov1 < cov2 ? cov2 : cov1
      bins[{ca, cb}] += 1_u64
    end

    private def each_unique_one_base_neighbor(kmer : UInt64, k : Int32, seen_neighbors : Array(UInt64), & : UInt64 ->)
      k.times do |pos|
        shift = 2 * (k - 1 - pos)
        current = (kmer >> shift) & 0b11_u64
        4.times do |base_i|
          base = base_i.to_u64
          next if base == current
          mask = ~(0b11_u64 << shift)
          mutated = (kmer & mask) | (base << shift)
          canonical = Kmer.canonical(mutated, Kmer.reverse_complement(mutated, k))
          next if seen_neighbors.includes?(canonical)
          seen_neighbors << canonical
          yield canonical
        end
      end
    end
  end
end
