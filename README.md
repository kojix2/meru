# meru

[![build](https://github.com/kojix2/meru/actions/workflows/build.yml/badge.svg)](https://github.com/kojix2/meru/actions/workflows/build.yml)
[![Lines of Code](https://img.shields.io/endpoint?url=https%3A%2F%2Ftokei.kojix2.net%2Fbadge%2Fgithub%2Fkojix2%2Fmeru%2Flines)](https://tokei.kojix2.net/github/kojix2/meru)
![Static Badge](https://img.shields.io/badge/PURE-Vibe_Coding-magenta)

`meru` is a small Crystal CLI for exploratory k-mer profiling in the terminal.

This is a simple project created with agentic AI coding. It displays [Smudgeplot](https://github.com/KamilSJaron/smudgeplot)-like heatmaps in the terminal.

## Build

```bash
make build release=1
```

Or:

```bash
shards build --release
```

## Usage

```bash
bin/meru reads.fq.gz -k 21 -o sample
```

Tiny example:

```bash
bin/meru spec/fixtures/tiny.fastq -k 3 -o tiny
```

Inputs can be FASTQ (`.fq`, `.fastq`, optionally `.gz`) or FASTA (`.fa`, `.fasta`, optionally `.gz`), detected by filename extension.

`--min-depth` and `--max-depth` define the histogram depth range. Pair extraction uses `max(2, --min-depth)` and `--max-depth` by default, so singleton error k-mers stay out of the smudge workflow unless you opt in explicitly. `--pair-min-depth` and `--pair-max-depth` override only the pair-extraction range. When a smudgeplot is shown, `meru` expands the effective pair max depth to `max_depth * 2` on the y-axis because the smudgeplot uses total coverage (`depth_a + depth_b`), not single-k-mer depth.
The histogram uses `log10(count + 1)` scaling by default. Use `--linear-hist` if you want raw linear counts instead.

Current limitation: `meru` stores k-mer counts in a standard in-memory `Hash(UInt64, UInt32)`. That keeps the implementation simple, but very large reference FASTA inputs such as whole human assemblies can exceed the hash capacity or available memory. In practice, `meru` is currently a better fit for read datasets and smaller references than for hg38-scale full-reference counting.

Main outputs:

- `sample.kmer_hist.tsv`
- `sample.smudge.tsv`
- `sample.signals.tsv`
- `sample.summary.txt`

## Examples

The `examples/` directory contains a reproducible synthetic workflow built around fictional `tanuki` genomes:

```bash
cd examples
rake tanuki MERU=../bin/meru
```

More detail is in [examples/README.md](examples/README.md).
