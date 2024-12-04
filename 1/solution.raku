#!/usr/bin/env raku

sub MAIN(Str:D $input, UInt:D :$part = 1) {
  given $part {
    when 1 { say part1 $input.IO.slurp } 
    when 2 { say part2 $input.IO.slurp } 
  }
}

sub part1($in) { ( [Z] $in.lines».words )».sort.flatmap({ @^a Z- @^b })».abs.sum }
sub part2($in) { ( [Z] $in.lines».words ).flatmap({ @^a Z* @^b.Bag{@^a} }).sum }