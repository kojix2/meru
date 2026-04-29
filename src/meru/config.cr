module Meru
  VERSION = "0.4.0"

  struct Config
    property k : Int32
    property output_prefix : String
    property threads : Int32
    property min_cov : Int32
    property max_cov : Int32?
    property? plot : Bool
    property input_paths : Array(String)
    property? hist_only : Bool
    property pair_min_cov : Int32
    property pair_max_cov : Int32?
    property? log_hist : Bool

    def initialize(
      @k : Int32 = 21,
      @output_prefix : String = "meru",
      @threads : Int32 = 1,
      @min_cov : Int32 = 1,
      @max_cov : Int32? = nil,
      @plot : Bool = true,
      @input_paths : Array(String) = [] of String,
      @hist_only : Bool = false,
      @pair_min_cov : Int32 = 2,
      @pair_max_cov : Int32? = nil,
      @log_hist : Bool = false,
    )
    end
  end
end
