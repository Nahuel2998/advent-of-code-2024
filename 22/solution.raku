#!/usr/bin/env raku

use MONKEY-GUTS;

sub evolve-seq(Int:D $num) {
  $num, {
    $_ .= &mix-prune:  6;
    $_ .= &mix-prune: -5;
    $_ .= &mix-prune: 11;
  } ... *
}

sub mix-prune(Int:D $num, Int:D $exp) { $num +^ $num +< $exp mod 16777216 }

sub gains(@offers) {
  my %gains;
  my $last = @offers[0];
  for @offers.rotor: 4 => -3 {
    my @chg = .[0]-$last, |(.[1..*-1] Z- .[0..*-2]);
    $last   = .[0];
    %gains{~@chg} //= .[*-1]
  } 
  %gains
}

sub MAIN(Str:D $file) {
  my $input = $file.IO.slurp;
  
  my @monkeys = $input.lines».Int;
  say "- - - - - - -";

  my @seqs = @monkeys.map: &evolve-seq;
  my @nums = @seqs.race.map(*[^2001]);
  say "Part 1: ", @nums.map(*[*-1]).sum;

  my @offers = @nums.race».map: * mod 10;
  my %gains  = @offers.race.map(&gains).flat.classify: *.key, :as(*.value);
  say "Part 2: ", %gains.max(*.value.sum).value.sum;
}
