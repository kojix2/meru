# meru

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
