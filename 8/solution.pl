#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Algorithm::Combinatorics qw(combinations);
use experimental 'say';

my @res;
my %antennas;
my ($x, $y) = (0, 0);
for (<>) {
  chomp;
  $x = 0;
  for (split '') {
    $res[$y][$x] = '.';
    push @{ $antennas{$_} }, [$x, $y] if /\w/;
    $x++;
  }
  $y++;
}

my ($width, $height) = ($x, $y);

sub flat { map { ref eq 'ARRAY' ? @$_ : $_ } @_ }

sub antinodes {
  my (($x1, $y1), ($x2, $y2)) = flat @_;
  my ($dx, $dy) = ($x1 - $x2, $y1 - $y2);

  my ($x, $y);

  ($x, $y) = ($x1, $y1);
  while (0 <= $x < $width && 0 <= $y < $height) {
    $res[$y][$x] = '#';
    $x += $dx;
    $y += $dy;
  }

  ($x, $y) = ($x2, $y2);
  while (0 <= $x < $width && 0 <= $y < $height) {
    $res[$y][$x] = '#';
    $x -= $dx;
    $y -= $dy;
  }
}

while (my ($k, $v) = each %antennas) {
  my $iter = combinations($v, 2);
  while (my $pair = $iter->next) { antinodes @$pair }
}

$_ = join "\n", map { join '', @$_ } @res;
say;
say tr/#//;