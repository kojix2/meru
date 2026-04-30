module Meru
  VERSION = "0.4.0"

  struct Config
    property k : Int32
    property output_prefix : String
    property threads : Int32
    property min_depth : Int32
    property max_depth : Int32?
    property? plot : Bool
    property input_paths : Array(String)
    property? hist_only : Bool
    property pair_min_depth : Int32?
    property pair_max_depth : Int32?
    property? log_scale : Bool
    property? linear_smudge : Bool
    property plot_width : Int32
    property plot_height : Int32

    def initialize(
      @k : Int32 = 21,
      @output_prefix : String = "meru",
      @threads : Int32 = 1,
      @min_depth : Int32 = 2,
      @max_depth : Int32? = nil,
      @plot : Bool = true,
      @input_paths : Array(String) = [] of String,
      @hist_only : Bool = false,
      @pair_min_depth : Int32? = nil,
      @pair_max_depth : Int32? = nil,
      @log_scale : Bool = false,
      @linear_smudge : Bool = false,
      @plot_width : Int32 = 80,
      @plot_height : Int32 = 20,
    )
    end

    def effective_pair_min_depth : Int32
      @pair_min_depth || @min_depth
    end

    def effective_pair_max_depth : Int32?
      @pair_max_depth || @max_depth
    end
  end
end
