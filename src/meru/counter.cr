module Meru
  alias KmerCounts = Hash(UInt64, UInt32)

  class Counter
    getter k : Int32
    getter counts : KmerCounts
    property total_reads : UInt64
    property total_bases : UInt64
    property valid_kmers : UInt64

    def initialize(@k : Int32)
      Kmer.validate_k!(@k)
      @counts = KmerCounts.new(0_u32)
      @total_reads = 0_u64
      @total_bases = 0_u64
      @valid_kmers = 0_u64
    end

    def add_sequence(seq : String | IO::Memory)
      @total_reads += 1
      add_sequence_bytes(seq.to_slice)
    end

    def add_sequence_bytes(bytes : Bytes)
      @total_bases += bytes.size.to_u64

      Kmer.each_canonical_bytes(bytes, @k) do |kmer|
        current = @counts[kmer]
        @counts[kmer] = current == UInt32::MAX ? UInt32::MAX : current + 1_u32
        @valid_kmers += 1
      end
    end

    def merge!(other : Counter)
      raise ArgumentError.new("cannot merge counters with different k") unless @k == other.k

      other.counts.each do |kmer, count|
        current = @counts[kmer]
        sum = current.to_u64 + count.to_u64
        @counts[kmer] = sum > UInt32::MAX ? UInt32::MAX : sum.to_u32
      end

      @total_reads += other.total_reads
      @total_bases += other.total_bases
      @valid_kmers += other.valid_kmers
    end

    def self.count_files(paths : Array(String), k : Int32) : Counter
      counter = Counter.new(k)
      paths.each do |path|
        FastqReader.new(path).each_sequence do |seq|
          counter.add_sequence(seq)
        end
      end
      counter
    end

    # Worker-local counters. With Crystal multithreading enabled this can use CPU parallelism.
    # Without it, the structure remains deterministic and easy to inspect.
    def self.count_files_parallel(paths : Array(String), k : Int32, threads : Int32, chunk_size : Int32 = 10_000) : Counter
      return count_files(paths, k) if threads <= 1

      jobs = Channel(Array(String)?).new(threads)
      results = Channel(Counter).new(threads)

      threads.times do
        spawn do
          local = Counter.new(k)
          loop do
            chunk = jobs.receive
            break if chunk.nil?
            chunk.each { |seq| local.add_sequence(seq) }
          end
          results.send(local)
        end
      end

      paths.each do |path|
        chunk = [] of String
        FastqReader.new(path).each_sequence_copy do |seq|
          chunk << seq
          if chunk.size >= chunk_size
            jobs.send(chunk)
            chunk = [] of String
          end
        end
        jobs.send(chunk) unless chunk.empty?
      end

      threads.times { jobs.send(nil) }

      merged = Counter.new(k)
      threads.times do
        merged.merge!(results.receive)
      end
      merged
    end
  end
end
