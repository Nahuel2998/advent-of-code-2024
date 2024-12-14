#!/usr/bin/env raku

use Data::Dump::Tree;

# NOTE: Quite ugly, but crazy enough

grammar Day11 {
  rule  TOP { <.ws> <code> }
  
  proto
  token op { * }
  token op:sym<*>  { <.sym> }
  token op:sym<%%> { <.sym> }
  
  rule  expr      { <op>? <term> }
  rule  exprchain { <expr> + }
  rule  selector  { <exprchain> '->' }
  rule  operation { <selector>? <exprchain> }

  proto
  token statement { * }
  rule  statement:sym<transform> { <operation>+ %% [';' \v*] }
  rule  statement:sym<print>     { '<-' $<text>=\V* }
  rule  statement:sym<block>     { '{' \v* <code> \v* '}' }
  rule  statement:sym<repeat>    { '^'<times=.num> <statement> }
  rule  statement:sym<def>       { <ident> '::' <statement> }
  rule  statement:sym<call>      { <ident> }

  rule  code { <statement> * %% \v* }
  
  proto
  token term { * }
  token term:sym<literal> { <literal> }
  token term:sym<call>    { <ident> }
  
  proto
  token literal { * }
  token literal:sym<num>   { <num> }
  token literal:sym<True>  { <.sym> }
  token literal:sym<False> { <.sym> }
  
  token num { \d+ }
  
  token ws { \h* }
}

package Op {
  class Def {
    has $.name;
    has $.statement;
  }
  
  class Repeat {
    has $.times;
    has $.statement;
  }
  
  class Print {
    has $.text;
  }
  
  class Transform {
    has @.operations;
  }
  
  class Operation {
    has $.selector;    
    has $.chain;
  }

  class ExprChain {
    has @.expr;
  }
  
  class Expr {
    has $.op;
    has $.term;
  }
  
  class Code {
    has @.statements;
  }

  class Call {
    has $.name;
  }
}

class Day11Interpreter {
  has $.code is required;
  has %.pebbles;
  has %!defs = %(
    :splt(  -> $_ {  .comb( .chars div 2 )».Int } ),
    :lngth( -> $_ { +.comb } ),
  );
  has %!ops = %(
    '*'  => &infix:<*>,
    '%%' => &infix:<%%>,
  );
  
  multi method run {
    self.run: $.code
  }
  multi method run(Op::Code $code) {
    self.run: $_ for $code.statements
  }
  multi method run(Op::Def $def) {
    %!defs{$def.name} = $def.statement
  }
  multi method run(Op::Repeat $repeat) {
    self.run: $repeat.statement for ^$repeat.times
  }
  multi method run(Op::Print $print) {
    say $print.text, %!pebbles.values.sum
  }
  multi method run(Op::Transform $transform) {
    %!pebbles = %!pebbles.race.map({
      my ($p, $val) = .key, .value;
      |(self.run: .chain, $p).map: * => $val with $transform.operations.first: -> $op { !$op.selector.defined || $p ~~ self.run: $op.selector, $p }
    }).Bag;
  }
  multi method run(Op::ExprChain $chain, $pebble) {
    my $res = $pebble;
    $res = self.run: $_, $res for $chain.expr;
    $res
  }
  multi method run(Op::Expr $expr, $pebble) {
    my $term = self.run: $expr.term, $pebble;
    return $term if !$expr.op;

    %!ops{$expr.op}($pebble, $term)
  }
  multi method run(Op::Call $func, $pebble) {
    %!defs{$func.name}($pebble)
  }
  # Bad since you can't do splt without -> but oh well
  multi method run(Op::Call $func) {
    self.run: %!defs{$func.name}
  }
  multi method run($term, $pebble) {
    $term
  }
}

class Day11Actions {
  method TOP($/)  { make $<code>.made }

  method code($/) { 
    make Op::Code.new: :statements( $<statement>».made ) 
  }

  method statement:sym<call>($/) {
    make Op::Call.new:   :name( ~$<ident> )
  }
  method statement:sym<def>($/) {
    make Op::Def.new:    :name( ~$<ident> ),  :statement( $<statement>.made )
  }
  method statement:sym<repeat>($/) { 
    make Op::Repeat.new: :times( +$<times> ), :statement( $<statement>.made )
  }
  method statement:sym<block>($/) { 
    make $<code>.made
  }
  method statement:sym<print>($/) { 
    make Op::Print.new: :text( ~$<text> )
  }
  method statement:sym<transform>($/) { 
    make Op::Transform.new: :operations( $<operation>».made )
  }
  
  method operation($/) {
    make Op::Operation.new: :selector( $<selector>.made ), :chain( $<exprchain>.made )
  }
  
  method selector($/)  { make $<exprchain>.made }
  method exprchain($/) { 
    make Op::ExprChain.new: :expr( $<expr>».made )
  }
  method expr($/) {
    make Op::Expr.new: :op( .Str with $<op> ), :term( $<term>.made )
  }

  method term:sym<literal>($/) { make $<literal>.made }
  method term:sym<call>($/)    { 
    make Op::Call.new: :name( ~$<ident> )
  }

  method literal:sym<num>($/)   { make +$<num> }
  method literal:sym<True>($/)  { make True }
  method literal:sym<False>($/) { make False }
}

sub MAIN(Str:D $file) {
  my $code = $file.IO.slurp;
  
  my $actions = Day11.parse($code, :actions(Day11Actions.new)).made;
  ddt $actions;
  say "- - - - - - -";
  my $interpreter = Day11Interpreter.new: :code($actions), :pebbles( $*IN.slurp.words.Bag );
  $interpreter.run
}
