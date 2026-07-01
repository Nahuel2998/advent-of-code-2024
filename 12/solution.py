#!/usr/bin/env python3

parser = __import__("argparse").ArgumentParser()
parser.add_argument("input", help="Path to input file", type=str)
args = parser.parse_args()

with open(args.input) as f:
  grid = [[h for h in l if h != "\n"] for l in f.readlines()]

# NOTE: Uninteresting solution since I just want to catch up to current day :(

oob    = lambda p: p[1] >= len(grid[0]) or p[0] >= len(grid) or -1 in (p[1], p[0])
matsum = lambda a, b: (a[0] + b[0], a[1] + b[1])

DIRS = ( (0, 1), (0, -1), (1, 0), (-1, 0) )

ises: list[Island] = []

@(dc := __import__("dataclasses")).dataclass
class Island:
  char:  str
  area:  int = 0
  perim: int = 0
  cells: list[tuple[int, int]] = dc.field(default_factory=list)

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

    self.cells.append(curr)
    if self not in ises:
      ises.append(self) 

    return self.area * self.perim

  # Beautiful is better than ugly
  sides = lambda self: (
    cells := (
      ft := __import__("functools")).reduce(
        lambda acc, p: ((b := __import__("bisect")).insort(acc[0][p[0]], p[1]), b.insort(acc[1][p[1]], p[0])) and acc,
        self.cells,
        ((dd := __import__("collections").defaultdict)(list), dd(list)),
      )
  ) and sum(
    ft.reduce(
      lambda acc, b: (
        lambda lasts, sides, cell, i: (sides, lasts) if self.__isOneOfUs(matsum(cell, DIRS[3 - i])) else (sides + 1, ls) if (ls := (lasts[0], cell[i < 2]) if i % 2 else (cell[i < 2], lasts[1])) and lasts[i % 2] != cell[i < 2] - 1 else (sides, ls)
      )(acc[1], acc[0], (b, a) if j else (a, b), i + 2*j),
      bs,
      (0, [-2] * 2)
    )[0]
    for i in range(2)
    for j in range(2)
    for a, bs in cells[j].items()
  )

  __isOneOfUs = lambda self, curr: not oob(curr) and grid[curr[0]][curr[1]] == self.char

visited: set = set()

print(sum(Island(grid[y][x]).cost((y, x)) for y in range(len(grid[0])) for x in range(len(grid))))
print(sum(i.area * i.sides() for i in ises))
