module Meru
  alias CoveragePair = Tuple(UInt32, UInt32)
  alias PairWorkerResult = PairTable | Exception

  class PairTable
    getter bins : Hash(CoveragePair, UInt64)

    def initialize(@bins : Hash(CoveragePair, UInt64) = Hash(CoveragePair, UInt64).new(0_u64))
    end

    def total_pairs : UInt64
      total = 0_u64
      @bins.each_value { |count| total += count }
      total
    end

    def empty? : Bool
      @bins.empty?
    end

    def add(cov_a : UInt32, cov_b : UInt32, count : UInt64 = 1_u64) : Nil
      ca = cov_a <= cov_b ? cov_a : cov_b
      cb = cov_a <= cov_b ? cov_b : cov_a
      @bins[{ca, cb}] += count
    end

    def merge!(other : PairTable) : Nil
      other.bins.each do |key, value|
        @bins[key] += value
      end
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

    def extract(
      counts : KmerCounts,
      k : Int32,
      min_depth : Int32 = 2,
      max_depth : Int32? = nil,
      threads : Int32 = 1,
    ) : PairTable
      Kmer.validate_k!(k)
      raise ArgumentError.new("pair min depth must be >= 1") if min_depth < 1
      raise ArgumentError.new("pair extraction threads must be >= 1") if threads < 1
      if max = max_depth
        raise ArgumentError.new("pair max depth must be >= pair min depth") if max < min_depth
      end

      min_depth_u = min_depth.to_u32
      max_depth_u = max_depth.try(&.to_u32) || UInt32::MAX
      if threads <= 1
        extract_single(counts, k, min_depth_u, max_depth_u)
      else
        extract_parallel(counts, k, min_depth_u, max_depth_u, threads)
      end
    end

    private def extract_single(
      counts : KmerCounts,
      k : Int32,
      min_depth_u : UInt32,
      max_depth_u : UInt32,
    ) : PairTable
      table = PairTable.new
      seen_neighbors = Array(UInt64).new(3 * k)

      counts.each do |kmer, cov1|
        process_kmer(kmer, cov1, counts, k, min_depth_u, max_depth_u, table, seen_neighbors)
      end

      table
    end

    private def extract_parallel(
      counts : KmerCounts,
      k : Int32,
      min_depth_u : UInt32,
      max_depth_u : UInt32,
      threads : Int32,
    ) : PairTable
      keys = counts.keys
      active_workers = Math.min(threads, keys.size)
      return PairTable.new if active_workers == 0

      chunk_size = (keys.size + active_workers - 1) // active_workers
      results = Channel(PairWorkerResult).new(active_workers)

      active_workers.times do |worker_id|
        start = worker_id * chunk_size
        stop = Math.min(start + chunk_size, keys.size)
        next if start >= stop

        spawn do
          begin
            local = PairTable.new
            seen_neighbors = Array(UInt64).new(3 * k)

            start.upto(stop - 1) do |idx|
              kmer = keys[idx]
              process_kmer(kmer, counts[kmer], counts, k, min_depth_u, max_depth_u, local, seen_neighbors)
            end

            results.send(local)
          rescue ex
            results.send(ex)
          end
        end
      end

      merged = PairTable.new
      active_workers.times do
        result = results.receive
        case result
        when PairTable
          merged.merge!(result)
        when Exception
          raise result
        end
      end
      merged
    end

    private def process_kmer(
      kmer : UInt64,
      cov1 : UInt32,
      counts : KmerCounts,
      k : Int32,
      min_depth_u : UInt32,
      max_depth_u : UInt32,
      table : PairTable,
      seen_neighbors : Array(UInt64),
    ) : Nil
      return unless depth_allowed?(cov1, min_depth_u, max_depth_u)

      seen_neighbors.clear
      each_unique_one_base_neighbor(kmer, k, seen_neighbors) do |neighbor|
        add_pair_if_valid(table, counts, kmer, cov1, neighbor, min_depth_u, max_depth_u)
      end
    end

    private def depth_allowed?(depth : UInt32, min_depth : UInt32, max_depth : UInt32) : Bool
      depth >= min_depth && depth <= max_depth
    end

    private def add_pair_if_valid(
      table : PairTable,
      counts : KmerCounts,
      kmer : UInt64,
      cov1 : UInt32,
      neighbor : UInt64,
      min_depth_u : UInt32,
      max_depth_u : UInt32,
    ) : Nil
      return if neighbor == kmer
      return unless kmer < neighbor
      cov2 = counts[neighbor]?
      return unless cov2
      return unless depth_allowed?(cov2, min_depth_u, max_depth_u)

      table.add(cov1, cov2)
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
