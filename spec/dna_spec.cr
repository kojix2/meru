require "./spec_helper"

describe Meru::DNA do
  it "encodes canonical DNA bases" do
    Meru::DNA.encode_base('A'.ord.to_u8).should eq 0_u64
    Meru::DNA.encode_base('C'.ord.to_u8).should eq 1_u64
    Meru::DNA.encode_base('G'.ord.to_u8).should eq 2_u64
    Meru::DNA.encode_base('T'.ord.to_u8).should eq 3_u64
  end

  it "rejects ambiguous bases" do
    Meru::DNA.encode_base('N'.ord.to_u8).should be_nil
  end
end
