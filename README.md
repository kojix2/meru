# meru

[![build](https://github.com/kojix2/meru/actions/workflows/build.yml/badge.svg)](https://github.com/kojix2/meru/actions/workflows/build.yml)
[![Lines of Code](https://img.shields.io/endpoint?url=https%3A%2F%2Ftokei.kojix2.net%2Fbadge%2Fgithub%2Fkojix2%2Fmeru%2Flines)](https://tokei.kojix2.net/github/kojix2/meru)
![Static Badge](https://img.shields.io/badge/PURE-Vibe_Coding-magenta)

`meru` is a small Crystal CLI for exploratory k-mer profiling in the terminal.

This is a simple project created with agentic AI coding. It displays Smudgeplot-like heatmaps in the terminal.

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
