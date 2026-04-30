require "option_parser"

require "./meru/config"
require "./meru/dna"
require "./meru/kmer"
require "./meru/sequence"
require "./meru/counter"
require "./meru/histogram"
require "./meru/pairs"
require "./meru/smudge"
require "./meru/signals"
require "./meru/plot"
require "./meru/summary"
require "./meru/cli"

Meru::CLI.run(ARGV)
