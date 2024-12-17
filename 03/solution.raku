#!/usr/bin/env raku

# NOTE: Overkill solution, but fun :)
sub MAIN(Str:D $input, UInt:D :$part = 1) {
  given $part {
    when 1 { say part1 $input.IO.slurp } 
    when 2 { say part2 $input.IO.slurp } 
  }
}

grammar Mully {
  token TOP { [ <op> | . ]* }
  
  proto 
  token op { * }
  token op:sym<do>    { "do()" }
  token op:sym<don't> { "don't()" }
  token op:sym<mul>   { mul '(' ~ ')' <term>**2 % ',' }

  token term { \d+ }
}

class MullyActions {
  has $!mul              = True;
  has $!eval-do is built = True;

  method TOP($/) { make $<op>>>.made.sum }
  
  method op:sym<do>($/)    { $!mul = True;  make 0 }
  method op:sym<don't>($/) { $!mul = False; make 0 }

  method op:sym<mul>($/) { make !$!eval-do || $!mul ?? [*] $<term> !! 0 }
}

sub part1($in) { Mully.parse( $in, :actions(MullyActions.new: :!eval-do) ).made }
sub part2($in) { Mully.parse( $in, :actions(MullyActions.new) ).made }
