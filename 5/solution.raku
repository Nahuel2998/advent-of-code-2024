#!/usr/bin/env raku

sub MAIN(Str:D $input, UInt:D :$part = 1) {
  given $part {
    when 1 { say part1 $input.IO.slurp } 
    when 2 { say part2 $input.IO.slurp } 
  }
}

sub parse-input($in) {
  $in.split("\n\n")>>.lines.&{ 
    .[0]>>.split('|').classify(*[0], :as(*[1])), 
    .[1]>>.split(','),
  }
}

sub valid-update(%rules, @update --> Bool:D) {
  !any @update.kv.map: -> $i, $_ { %rules{$_}.first: { $_ (elem) @update[^$i] } }
}

sub part1($in) {
  my (%rules, @updates) := parse-input $in;
  @updates.map({ 
    ( valid-update %rules, $_ ) 
    && .[* div 2] 
  }).sum
}
sub part2($in) {
  my (%rules, @updates) := parse-input $in;
  @updates.map({ 
    ( !valid-update %rules, $_ ) 
    && .sort({ $^b (elem) %rules{$^a} ?? Less !! More }).[* div 2]
  }).sum
}