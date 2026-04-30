require "unicode_plot"

module Meru
  module Plot
    extend self

    DEFAULT_PLOT_WIDTH  = 72
    DEFAULT_PLOT_HEIGHT = 18

    def histogram(
      hist : Histogram,
      min_depth : Int32 = 1,
      max_depth : Int32? = nil,
      log_y : Bool = false,
      io : IO = STDOUT,
      width : Int32 = DEFAULT_PLOT_WIDTH,
      height : Int32 = DEFAULT_PLOT_HEIGHT,
    )
      Unicode.histogram(hist, min_depth, max_depth, log_y, io, width, height)
    end

    def smudge(
      smudges : SmudgeTable,
      max_total_cov : Int32? = nil,
      log_counts : Bool = true,
      io : IO = STDOUT,
      width : Int32 = 60,
      height : Int32 = 20,
    )
      Unicode.smudge(smudges, max_total_cov, log_counts, io, width, height)
    end

    def smudge_display_max_total_cov(max_depth : Int32?) : Int32?
      return unless value = max_depth
      return Int32::MAX if value > Int32::MAX // 2
      value * 2
    end

    def signals(signals : Array(Signal), io : IO = STDOUT)
      Text.signals(signals, io)
    end

    module Unicode
      extend self

      def histogram(
        hist : Histogram,
        min_depth : Int32 = 1,
        max_depth : Int32? = nil,
        log_y : Bool = false,
        io : IO = STDOUT,
        width : Int32 = DEFAULT_PLOT_WIDTH,
        height : Int32 = DEFAULT_PLOT_HEIGHT,
      )
        x = [] of Float64
        y = [] of Float64

        hist.each_bin(min_depth, max_depth) do |cov, count|
          x << cov.to_f
          y << histogram_value(count, log_y)
        end

        if x.empty?
          io.puts "K-mer coverage histogram"
          io.puts
          io.puts "(no k-mers in selected coverage range)"
          return
        end

        ylabel = log_y ? "log10(distinct k-mers + 1)" : "distinct k-mers"
        plot = ::UnicodePlot.lineplot(
          x,
          y,
          title: "k-mer coverage histogram",
          xlabel: "coverage",
          ylabel: ylabel,
          width: width,
          height: height,
          canvas: :braille,
        )
        io.puts plot
      end

      private def histogram_value(count : UInt64, log_y : Bool) : Float64
        value = count.to_f
        log_y ? Math.log10(value + 1.0) : value
      end

      def smudge(
        smudges : SmudgeTable,
        max_total_cov : Int32? = nil,
        log_counts : Bool = true,
        io : IO = STDOUT,
        width : Int32 = 60,
        height : Int32 = 20,
      )
        if smudges.bins.empty?
          io.puts "Smudgeplot"
          io.puts
          io.puts "(no k-mer pairs in selected coverage range)"
          return
        end

        x_bins = width.clamp(10, Int32::MAX)
        y_bins = (height * 2).clamp(10, Int32::MAX)
        y_max = max_total_cov.try(&.to_u64) || smudges.max_total_coverage
        y_max = 1_u64 if y_max < 1_u64
        matrix = smudge_matrix(smudges, y_max, x_bins, y_bins, log_counts)

        plot = ::UnicodePlot.heatmap(
          matrix,
          title: "Smudgeplot",
          xlabel: "minor ratio",
          ylabel: "total coverage",
          zlabel: smudge_zlabel(log_counts),
          xoffset: 0.0,
          xfact: x_bins > 1 ? 0.5 / (x_bins - 1).to_f : 0.5,
          yoffset: 0.0,
          yfact: y_bins > 1 ? y_max.to_f / (y_bins - 1).to_f : y_max.to_f,
          xlim: {0.0, 0.5},
          ylim: {0.0, y_max.to_f},
          width: width,
          height: height,
          colorbar: true,
        )

        io.puts plot
        io.puts
        io.puts "Expected ratios: AAAB≈0.25, AAB≈0.33, AB/AABB≈0.50"
      end

      private def smudge_matrix(
        smudges : SmudgeTable,
        y_max : UInt64,
        x_bins : Int32,
        y_bins : Int32,
        log_counts : Bool,
      ) : Array(Array(Float64))
        matrix = Array.new(y_bins) { Array.new(x_bins, 0.0) }

        smudges.bins.each do |key, count|
          minor = key[0]
          total = key[1]
          next if total == 0_u64 || total > y_max

          ratio = minor.to_f / total.to_f
          x = ((ratio / 0.5) * (x_bins - 1)).round.to_i
          y = ((total.to_f / y_max.to_f) * (y_bins - 1)).round.to_i
          x = x.clamp(0, x_bins - 1)
          y = y.clamp(0, y_bins - 1)
          matrix[y][x] += count.to_f
        end

        matrix.map do |row|
          row.map { |value| smudge_value(value, log_counts) }
        end
      end

      private def smudge_value(value : Float64, log_counts : Bool) : Float64
        return Float64::NAN if value <= 0.0
        log_counts ? Math.log10(value + 1.0) : value
      end

      private def smudge_zlabel(log_counts : Bool) : String
        log_counts ? "log10(pair count + 1)" : "pair count"
      end
    end

    module Text
      extend self

      def smudge(
        smudges : SmudgeTable,
        max_total_cov : Int32? = nil,
        log_counts : Bool = true,
        io : IO = STDOUT,
        width : Int32 = 60,
        height : Int32 = 20,
      )
        io.puts "Smudge density"
        io.puts
        if smudges.bins.empty?
          io.puts "(no k-mer pairs in selected coverage range)"
          return
        end

        x_bins = width
        y_bins = height
        y_max = max_total_cov.try(&.to_u64) || smudges.max_total_coverage
        y_max = 1_u64 if y_max < 1_u64

        matrix = Array.new(y_bins) { Array.new(x_bins, 0_u64) }
        smudges.bins.each do |key, count|
          minor = key[0]
          total = key[1]
          next if total == 0_u64 || total > y_max
          ratio = minor.to_f / total.to_f
          x = ((ratio / 0.5) * (x_bins - 1)).round.to_i
          x = 0 if x < 0
          x = x_bins - 1 if x >= x_bins
          y = ((total.to_f / y_max.to_f) * (y_bins - 1)).round.to_i
          y = 0 if y < 0
          y = y_bins - 1 if y >= y_bins
          matrix[y][x] += count
        end

        max_value = 0_u64
        matrix.each { |row| row.each { |v| max_value = v if v > max_value } }
        chars = [' ', '.', ':', '-', '=', '+', '*', '#', '%', '@']
        label_width = y_max.to_s.size

        (y_bins - 1).downto(0) do |y|
          cov_label = ((y.to_f / (y_bins - 1).to_f) * y_max.to_f).round.to_u64
          line = String.build do |row_io|
            matrix[y].each do |value|
              idx = density_index(value, max_value, chars.size, log_counts)
              row_io << chars[idx]
            end
          end
          io.puts "#{cov_label.to_s.rjust(label_width)} |#{line}|"
        end

        io.puts "#{"".rjust(label_width)} +#{"-" * x_bins}+"
        io.puts "#{"".rjust(label_width)}  0.0  minor ratio  0.5"
        io.puts
        io.puts "Expected ratios: AAAB≈0.25, AAB≈0.33, AB/AABB≈0.50"
      end

      def signals(signals : Array(Signal), io : IO = STDOUT)
        io.puts "Smudge signals"
        io.puts
        signals.each do |signal|
          io.puts "#{signal.label}: #{signal.strength} (support: #{signal.support})"
        end
      end

      private def density_index(value : UInt64, max_value : UInt64, palette_size : Int32, log_counts : Bool) : Int32
        return 0 if value == 0_u64 || max_value == 0_u64
        value_f = log_counts ? Math.log10(value.to_f + 1.0) : value.to_f
        max_f = log_counts ? Math.log10(max_value.to_f + 1.0) : max_value.to_f
        scaled = ((value_f / max_f) * (palette_size - 1)).ceil.to_i
        scaled < 1 ? 1 : scaled
      end
    end
  end
end
