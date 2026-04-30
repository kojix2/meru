require "fastx"

module Meru
  class SequenceReadError < Exception
  end

  class SequenceReader
    getter path : String

    def initialize(@path : String)
    end

    def each_sequence(& : IO::Memory ->)
      case detect_format(@path)
      in .fastq?
        Fastx::Fastq::Reader.open(@path) do |reader|
          reader.each do |_, sequence, _|
            yield sequence
          end
        end
      in .fasta?
        Fastx::Fasta::Reader.open(@path) do |reader|
          reader.each do |_, sequence|
            yield sequence
          end
        end
      end
    rescue ex
      raise ex if ex.is_a?(SequenceReadError)
      raise SequenceReadError.new("failed to read sequence file #{@path}: #{ex.message}")
    end

    def each_sequence_copy(& : String ->)
      case detect_format(@path)
      in .fastq?
        Fastx::Fastq::Reader.open(@path) do |reader|
          reader.each_copy do |_, sequence, _|
            yield sequence
          end
        end
      in .fasta?
        Fastx::Fasta::Reader.open(@path) do |reader|
          reader.each_copy do |_, sequence|
            yield sequence
          end
        end
      end
    rescue ex
      raise ex if ex.is_a?(SequenceReadError)
      raise SequenceReadError.new("failed to read sequence file #{@path}: #{ex.message}")
    end

    private enum Format
      Fasta
      Fastq
    end

    private def detect_format(path : String) : Format
      downcased = path.downcase
      return Format::Fasta if matches_extension?(downcased, [".fa", ".fasta", ".fa.gz", ".fasta.gz"])
      return Format::Fastq if matches_extension?(downcased, [".fq", ".fastq", ".fq.gz", ".fastq.gz"])

      raise SequenceReadError.new("unsupported input format for #{path}; use .fa/.fasta or .fq/.fastq (optionally .gz)")
    end

    private def matches_extension?(path : String, extensions : Array(String)) : Bool
      extensions.any? { |ext| path.ends_with?(ext) }
    end
  end

  alias FastqReader = SequenceReader
  alias FastqError = SequenceReadError
end
