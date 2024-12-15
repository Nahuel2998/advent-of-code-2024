#!/usr/bin/env python3

import argparse
from dataclasses import dataclass

parser = argparse.ArgumentParser()
parser.add_argument("input", help="Path to input file", type=str)
args = parser.parse_args()

with open(args.input) as f:
  grid = [[h for h in l if h != "\n"] for l in f.readlines()]

# NOTE: Uninteresting solution since I just want to catch up to current day :(
# NOTE: Part 1 only, for now

oob    = lambda p: p[1] >= len(grid[0]) or p[0] >= len(grid) or -1 in (p[1], p[0])
matsum = lambda a, b: (a[0] + b[0], a[1] + b[1])

DIRS = ( (0, 1), (0, -1), (1, 0), (-1, 0) )

@dataclass
class Island:
  char:  str
  area:  int = 0
  perim: int = 0

  def cost(self, curr: tuple[int, int]) -> int:
    if curr in visited:
      return 0
    
    visited.add(curr)

    self.area  += 1
    self.perim += 4

    for c in (matsum(curr, d) for d in DIRS):
      if self.__isOneOfUs(c):
        self.perim -= 1
        self.cost(c)

    return self.area * self.perim
  
  __isOneOfUs = lambda self, curr: not oob(curr) and grid[curr[0]][curr[1]] == self.char

visited: set = set()

print(sum(Island(grid[y][x]).cost((y, x)) for y in range(len(grid[0])) for x in range(len(grid))))