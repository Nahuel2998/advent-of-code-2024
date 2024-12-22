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
  #       Raku's regex engine hangs on the first impossible pattern, possibly due to catastrophic backtracking
  #       So this will do instead
  say "Part 1: ", @patterns».&solve».Bool.sum;
  say "Part 2: ", @patterns».&solve.sum;
}
