require "fastx"

module Meru
  class FastqError < Exception
  end

  class FastqReader
    getter path : String

    def initialize(@path : String)
    end

    def each_sequence(& : IO::Memory ->)
      Fastx::Fastq::Reader.open(@path) do |reader|
        reader.each do |_, sequence, _|
          yield sequence
        end
      end
    rescue ex
      raise FastqError.new("failed to read FASTQ #{@path}: #{ex.message}")
    end

    def each_sequence_copy(& : String ->)
      Fastx::Fastq::Reader.open(@path) do |reader|
        reader.each_copy do |_, sequence, _|
          yield sequence
        end
      end
    rescue ex
      raise FastqError.new("failed to read FASTQ #{@path}: #{ex.message}")
    end
  end
end
