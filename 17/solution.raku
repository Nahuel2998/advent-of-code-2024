#!/usr/bin/env raku

enum Register <A B C>;

constant adv = 0;
constant bxl = 1;
constant bst = 2;
constant jnz = 3;
constant bxc = 4;
constant out = 5;
constant bdv = 6;
constant cdv = 7;

class Interpreter {
  has @.instructions;
  has @.register;
  has @.res;
  has $.ip = 0;
  
  my @insts = <adv bxl bst jnz bxc out bdv cdv>;
  my @opnds = <0 1 2 3 A B C !>;
  
  multi method run(:$debug, :$quiet) { 
    while $!ip < @!instructions {
      my ($inst, $v) = @!instructions[$!ip..$!ip + 1];
      say "@insts[$inst] @opnds[$v] | @!register[]».base(2)" if $debug;

      self.run: $inst, $v;
      $!ip += 2;
    }
    say @!res.join: ',' unless $quiet;
  }

  multi method run(adv, $_) { @!register[A] +>= self.combo($_) }
  multi method run(bxl, $_) { @!register[B] +^= $_ }
  multi method run(bst, $_) { @!register[B]   = self.combo($_) % 8 }
  multi method run(jnz, $_) { $!ip            = $_ - 2 if @!register[A] }
  multi method run(bxc, $_) { @!register[B] +^= @!register[C] }
  multi method run(out, $_) { @!res.push:       self.combo($_) % 8 }
  multi method run(bdv, $_) { @!register[B]   = @!register[A] +> self.combo($_) }
  multi method run(cdv, $_) { @!register[C]   = @!register[A] +> self.combo($_) }
  
  subset ComboLiteral  of Int where * ~~ 0..3;
  subset ComboRegister of Int where * ~~ 4..6;
  subset Invalid       of Int where * ~~    7;

  multi method combo(ComboLiteral  $_) { $_ }
  multi method combo(ComboRegister $_) { @!register[$_ - 4] }
  multi method combo(Invalid       $_) { !!! }
  
  method reset($A, $B = 0, $C = 0) {
    @!register = $A, $B, $C;
    @!res      = ();
    $!ip       = 0;
  }
  
  method decompiled(--> Str:D) { decompile @!instructions }
  
  sub decompile(+@instructions --> Str:D) {
    @instructions.map(-> $inst, $_ { "@insts[$inst] @opnds[$_]" }).join: "\n"
  }

  method reverse(Int:D $solution = 0) {
    if $solution > 8 ** 15 { return $solution }

    |gather for 0..7 {
      my $a = $_ + $solution +< 3;

      self.reset: $a;
      self.run: :quiet;

      if @!instructions[*-@!res..*] eq @!res && self.reverse: $a -> $_ {
        .take
      }
    }
  }
}

grammar Input {
  rule  TOP { <register> ** 3 <program> }

  rule  register { Register $<name>=\w ':' <num> }
  rule  program  { Program ':' <instruction>+ }

  token instruction { <operator=.num> ',' <operand=.num> ','? }
  
  token num { \d+ }
}

class InputActions {
  method TOP($/) {
    make Interpreter.new: :register( $<register>».made ), :instructions( $<program>.made )
  }
  
  method register($/) { make +$<num> }
  method program($/)  { make  $<instruction>».made }

  method instruction($/) { make Slip.new: +$<operator>, +$<operand> }
}

sub MAIN(Str:D $file) {
  my $input = $file.IO.slurp;
  
  my $interpreter = Input.parse( $input, :actions(InputActions.new) ).made;
  say $interpreter; 
  say $interpreter.decompiled; 
  say "- - - - - - -";
  say "Part 1:";
  $interpreter.run;
  say "- - - - - - -";
  say "Part 2:";
  my $res = $interpreter.reverse;
  say $res;
  $interpreter.reset: $res[0];
  $interpreter.run: :debug;
}
