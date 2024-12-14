#!/usr/bin/env python3

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("input", help="Name of the input file", type=str)
args = parser.parse_args()

with open(args.input) as f:
  island = [[int(h) for h in l if h != "\n"] for l in f.readlines()]
  
solve      = lambda visited, curr, want, reduce: ((),) if curr in visited or (lambda pos: pos[1] >= len(island[0]) or pos[0] >= len(island) or -1 in (pos[1], pos[0]))(curr) or island[curr[0]][curr[1]] != want else (curr,) if want == 9 else reduce(s for i in (solve(visited | set((curr,)), (curr[0] + d[0], curr[1] + d[1]), want + 1, reduce) for d in ((0, 1), (0, -1), (1, 0), (-1, 0))) for s in i)
solve_with = lambda reduce: len(tuple(s for i in (solve(set(), (y, x), 0, reduce) for y in range(len(island[0])) for x in range(len(island))) for s in i if s != ()))

print("Part 1:", solve_with(set))
print("Part 2:", solve_with(tuple))
