# Examples

This directory now centers on a fictional lineage called the `tanuki` tribe.

The goal is to make `meru` feel like a small, end-to-end genome profiling workflow:

1. create tiny synthetic genomes for related organisms
2. simulate single-end whole-genome reads
3. run `meru` on those reads
4. compare the terminal histogram and smudge heatmap

The current defaults use a slightly larger toy simulation than before:
each monoploid chromosome is `3600 bp`, and the default read depth is scaled up to match.

## Tanuki lineage

The tanuki organisms all share nearly the same monoploid genome, but differ in ploidy and haplotype composition:

- `tanuki1`: ploidy 1, haplotype composition `A`
- `tanuki2`: ploidy 2, haplotype composition `A + B`
- `tanuki4`: ploidy 4, haplotype composition `A + B + C + D`
- `tanuki8`: ploidy 8, haplotype composition `A x7 + B x1`

In this story, haplotypes `A`, `B`, `C`, and `D` are closely related versions of the same chromosome with spaced SNP differences.
Some SNPs are private to a single haplotype, and some are shared by exactly two haplotypes.

That means the expected minor-ratio story is:

- `tanuki1`: no heterozygous smudge
- `tanuki2`: about `1/2 = 0.50`
- `tanuki4`: a mix of `1/4 = 0.25` private variants and `2/4 = 0.50` shared-pair variants
- `tanuki8`: about `1/8 = 0.125`

Because `meru` uses a deliberately simple pair-extraction and signal heuristic, the observed `tanuki4` pattern will not look like a perfect biological decomposition.
The point of `tanuki4` is to show that a tetraploid can contain both one-copy and two-copy variant classes at the same time.

## One-shot workflow

Build `meru`, then generate genomes, simulate reads, and run the whole comparison:

```bash
make build release=1
cd examples
rake tanuki MERU=../bin/meru
```

You can also control the terminal plot size used by `meru`:

```bash
cd examples
rake tanuki MERU=../bin/meru WIDTH=100 HEIGHT=24
```

That command is meant to be the main experience: it prints the three most informative smudge heatmaps first.
To stay closer to the original `smudgeplot` project, the interactive view foregrounds the smudge heatmap rather than the k-mer histogram.
The x-axis stays at minor ratio `0.0..0.5`, while the y-axis is allowed to scale naturally for each tanuki.

The order is:

1. `tanuki2` smudge
2. `tanuki4` smudge
3. `tanuki8` smudge
4. final summary table

`tanuki1` is still generated and included in the saved summary, but omitted from the main interactive heatmap section because it is haploid and usually has no smudge.

This writes a complete demo set under `examples/out/tanuki/`:

```text
examples/out/tanuki/README.txt
examples/out/tanuki/genomes/tanuki1.fa
examples/out/tanuki/genomes/tanuki2.fa
examples/out/tanuki/genomes/tanuki4.fa
examples/out/tanuki/genomes/tanuki8.fa
examples/out/tanuki/reads/tanuki1.fastq
examples/out/tanuki/meru/tanuki1_terminal.txt
examples/out/tanuki/meru/tanuki2_terminal.txt
examples/out/tanuki/meru/tanuki4_terminal.txt
examples/out/tanuki/meru/tanuki8_terminal.txt
```

The most useful saved files are:

- `genomes/*.fa`: the fictional reference genomes for each tanuki subtype
- `reads/*.fastq`: simulated single-end reads
- `meru/*_terminal.txt`: captured terminal output, from which the workflow highlights the smudge section
- `meru/*.signals.tsv`: rough `AB / AAB / AAAB / AABB` summary
- `meru/*.smudge.tsv`: raw minor-ratio and total-coverage bins

## Inspecting the results

If you want to revisit the terminal plots afterward, look at the captured files:

```bash
sed -n '/Smudgeplot/,$p' examples/out/tanuki/meru/tanuki1_terminal.txt
sed -n '/Smudgeplot/,$p' examples/out/tanuki/meru/tanuki2_terminal.txt
sed -n '/Smudgeplot/,$p' examples/out/tanuki/meru/tanuki4_terminal.txt
sed -n '/Smudgeplot/,$p' examples/out/tanuki/meru/tanuki8_terminal.txt
```

What you should see:

- `tanuki1`: almost no smudge because there is only one haplotype
- `tanuki2`: a hotspot near minor ratio `0.50`
- `tanuki4`: signal near both `0.25` and `0.50`, reflecting private SNPs and shared-pair SNPs
- `tanuki8`: a hotspot near minor ratio `0.125`, with higher total coverage

Also inspect the summary report:

```bash
sed -n '1,200p' examples/out/tanuki/README.txt
```

That report condenses the observed peak coverage, dominant minor ratio, and `meru` signal labels for all four tanuki organisms.
It also records the base seed and the per-species read seeds used for that run.

## Individual steps

If you want to run the stages separately:

Generate genomes:

```bash
cd examples
rake genomes
```

If you prefer to run the lower-level scripts directly, you still can.
Simulate single-end reads for one organism:

```bash
ruby examples/simulate_tanuki_reads.rb \
  --genome examples/out/tanuki/genomes/tanuki4.fa \
  --output examples/out/tanuki/reads/tanuki4.fastq
```

Run `meru` on one organism:

```bash
bin/meru \
  examples/out/tanuki/reads/tanuki4.fastq \
  -k 21 \
  -o examples/out/tanuki/meru/tanuki4 \
  --plot-width 100 \
  --plot-height 24
```

## Notes

- The read simulator is intentionally self-contained and written in Ruby, so the example does not require external tools.
- The simulator currently favors clean educational reads over realistic sequencing noise, because that makes the ploidy-dependent smudges easier to see in `meru`.
- The genomes are still tiny and artificial on purpose; this is for visualization and intuition, not realism.
- `tanuki4` is intentionally not an `AAAB` toy anymore; it is built from four related haplotypes with both one-copy and two-copy variant classes.
- `tanuki8` is included to show that `meru` can still produce a visible smudge pattern outside the simple `AB / AAB / AAAB` labels without being quite so extreme.
- The `tanuki4` and `tanuki8` examples are most useful as visual heatmap demos; the rough `signals.tsv` labels are intentionally much simpler than the underlying ploidy story.
- The interactive workflow intentionally foregrounds the smudge heatmap, because that is the closest match to the original `smudgeplot` experience.
- `examples/Rakefile` is the intended entry point for the demo workflow.
