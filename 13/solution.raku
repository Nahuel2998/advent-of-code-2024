#!/usr/bin/env raku

use Math::Matrix;

class Point {
  has $.x is required;
  has $.y is required;
  
  method add(Int:D $amt) {
    $!x += $amt;
    $!y += $amt;
  }
}

class ClawMachine {
  has Point:D $.a     is required;
  has Point:D $.b     is required;
  has Point:D $.prize is required;
  
  #| Amount of tokens to solve, if possible
  method tokens {
    my $btn = Math::Matrix.new: ([$!a.x, $!b.x], [$!a.y, $!b.y]);
    my $prz = Math::Matrix.new: ([$!prize.x],    [$!prize.y]);
    my ($a, $b) = |($btn ** -1).dot-product: $prz;
    ?(($a & $b) %% 1) && $a * 3 + $b
  }
}

grammar Input {
  rule  TOP { <machine> + }  
  
  rule  machine { <button> ** 2 <prize> }
  
  rule  button { 'Button' $<name>=\w ':' 'X' <x=.num> ',' 'Y' <y=.num> }
  rule  prize  { 'Prize:' 'X=' <x=.num> ',' 'Y=' <y=.num> }
 
  token num { <[+-]>? \d+ }
}

class InputActions {
  method TOP($/) { make $<machine>».made }
  
  method machine($/) {
    make ClawMachine.new: :a( $<button>[0].made ),
                          :b( $<button>[1].made ),
                          :prize( $<prize>.made ),
  }
  
  method button($/) { make Point.new: :x( +$<x> ), :y( +$<y> ) }
  method prize($/)  { make Point.new: :x( +$<x> ), :y( +$<y> ) }
}

sub MAIN(Str:D $file) {
  my $input = $file.IO.slurp;
  
  my @machines = Input.parse($input, :actions(InputActions.new)).made;
  say "Part 1: ", @machines».tokens.sum;
  
  .prize.add: 10_000_000_000_000 for @machines;
  say "Part 2: ", @machines».tokens.sum;
}
