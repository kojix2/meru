module Meru
  module Kmer
    extend self

    alias Encoded = UInt64

    MAX_K = 32

    def validate_k!(k : Int32)
      raise ArgumentError.new("k must be between 1 and #{MAX_K}") unless 1 <= k <= MAX_K
    end

    # Rolling 2-bit encoding keeps the implementation compact while avoiding
    # re-encoding every window from scratch.
    def each_canonical(seq : String | IO::Memory, k : Int32, & : Encoded ->)
      each_canonical_bytes(seq.to_slice, k) do |kmer|
        yield kmer
      end
    end

    def each_canonical_bytes(bytes : Bytes, k : Int32, & : Encoded ->)
      validate_k!(k)
      return if bytes.size < k

      mask = window_mask(k)
      forward = 0_u64
      reverse = 0_u64
      valid_bases = 0
      rc_shift = 2 * (k - 1)

      bytes.each do |byte|
        base = DNA.encode_base(byte)
        unless base
          forward = 0_u64
          reverse = 0_u64
          valid_bases = 0
          next
        end

        forward = ((forward << 2) | base) & mask
        reverse = (reverse >> 2) | (DNA.complement_bits(base) << rc_shift)
        valid_bases += 1

        next unless valid_bases >= k
        yield canonical(forward, reverse)
      end
    end

    def canonical(forward : Encoded, reverse_complement : Encoded) : Encoded
      forward < reverse_complement ? forward : reverse_complement
    end

    def reverse_complement(kmer : Encoded, k : Int32) : Encoded
      validate_k!(k)
      rc = 0_u64
      k.times do |i|
        base = (kmer >> (2 * i)) & 0b11_u64
        rc = (rc << 2) | DNA.complement_bits(base)
      end
      rc
    end

    private def window_mask(k : Int32) : UInt64
      return UInt64::MAX if k == MAX_K
      (1_u64 << (2 * k)) - 1_u64
    end
  end
end
