module Meru
  module DNA
    extend self

    # A/a => 0, C/c => 1, G/g => 2, T/t => 3. Other bases are invalid.
    def encode_base(byte : UInt8) : UInt64?
      case byte
      when 'A'.ord.to_u8, 'a'.ord.to_u8
        0_u64
      when 'C'.ord.to_u8, 'c'.ord.to_u8
        1_u64
      when 'G'.ord.to_u8, 'g'.ord.to_u8
        2_u64
      when 'T'.ord.to_u8, 't'.ord.to_u8
        3_u64
      end
    end

    def complement_bits(bits : UInt64) : UInt64
      bits ^ 0b11_u64
    end
  end
end
