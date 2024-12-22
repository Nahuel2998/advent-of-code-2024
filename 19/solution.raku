#!/usr/bin/env raku

use experimental :cached;

my @towels;

sub solve($pattern) is cached {
  return 1 unless $pattern;
  return @towels.map({ solve $pattern.substr: .chars if $pattern.starts-with: $_ }).sum
}

sub MAIN(Str:D $file) {
  my $input = $file.IO.slurp;
  
  my @patterns;
  given $input.split: "\n\n" {
    @towels   = .[0].split: ", ";
    @patterns = .[1].lines;
  }
  say "- - - - - - -";
  # NOTE: Previously I had solved Part 1 with grep alone
  #       But when I tried it using Raku regexes, the number was 12 lower than expected...
  #       Probably has to do with backtracking or/and an evil optimization, should likely be reported
  say "Part 1: ", @patterns».&solve».Bool.sum;
  say "Part 2: ", @patterns».&solve.sum;
}
