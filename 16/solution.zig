// This is my first time on zig, this likely sucks
const std = @import("std");

const DIR: [4]Pos = .{
    .{.x =  1, .y =  0}, // east
    .{.x =  0, .y =  1}, // south
    .{.x = -1, .y =  0}, // west
    .{.x =  0, .y = -1}, // north
};

const Pos  = struct {
    x: i16,
    y: i16,

    fn add(self: Pos, other: Pos) Pos {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }
};
const Cell = struct {
    solid: bool,
    cost:  u32 = 0,
};
const Grid = struct {
    width:  usize,
    height: usize,
    start:  Pos,
    end:    Pos,

    data: []Cell,

    pub fn fromInput(allocator: std.mem.Allocator, input: []const u8) !Grid {
        var width: usize = 0;
        var start: Pos   = undefined;
        var end:   Pos   = undefined;
        var data:  std.ArrayList(Cell) = .empty;

        var pos = Pos{.x = 0, .y = 0};
        for (input) |ch| {
            if (ch == '\n') {
                if (width == 0) {
                    width = @intCast(pos.x);
                }
                pos.x  = 0;
                pos.y += 1;
                continue;
            }

            try data.append(allocator, .{.solid = ch == '#'});

            switch (ch) {
                'S'  => start = pos,
                'E'  => end   = pos,
                else => {},
            }

            pos.x += 1;
        }
        if (input[input.len - 1] != '\n') {
            pos.y += 1;
        }

        return .{
            .width  = width,
            .height = @intCast(pos.y),
            .start  = start,
            .end    = end,
            .data   = data.items,
        };
    }

    fn cellAt(self: *Grid, pos: Pos) *Cell {
        return &self.data[self.posToIndex(pos)];
    }

    fn posToIndex(self: Grid, pos: Pos) usize {
        // Since the maze is surrounded by walls on all sides,
        // we can skip bound-checking
        const posy: usize = @intCast(pos.y);
        const posx: usize = @intCast(pos.x);
        return posy * self.width + posx;
    }

    fn print(self: *Grid) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const cell = self.cellAt(.{.x = @intCast(x), .y = @intCast(y)});
                if (cell.solid) {
                    std.debug.print("#", .{});
                // } else if (cell.restable) {
                //     std.debug.print("O", .{});
                } else {
                    std.debug.print(".", .{});
                }
            }
            std.debug.print("\n", .{});
        }
    }
};

pub fn main(init: std.process.Init) !void {
    const alloc = init.arena.allocator();

    const input = @embedFile("input");
    var   grid  = try Grid.fromInput(alloc, input);
    std.debug.print("Part 1: {}\n", .{part1(&grid)});
    // std.debug.print("Part 2: {}\n", .{part2(&grid)});
}

fn part1(grid: *Grid) u32 {
    calculateCosts(grid, grid.start, 0, 0);
    return grid.cellAt(grid.end).cost;
}

fn calculateCosts(grid: *Grid, pos: Pos, dir: u2, cost: u32) void {
    var cell = grid.cellAt(pos);
    if (cell.solid) {
        return;
    }

    if (cell.cost != 0 and cell.cost <= cost) {
        return;
    }

    cell.cost = cost;
    calculateCosts(grid, pos.add(DIR[dir     ]), dir     , cost + 1);
    calculateCosts(grid, pos.add(DIR[dir +% 1]), dir +% 1, cost + 1 + 1000);
    calculateCosts(grid, pos.add(DIR[dir -% 1]), dir -% 1, cost + 1 + 1000);
}

test "example" {
    const input = @embedFile("example");

    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();

    var grid = try Grid.fromInput(arena.allocator(), input);

    const p1 = part1(&grid);
    // const p2 = part2(&grid);
    std.debug.print(
        "{}, {}, {}, {}",
        .{
            grid.cellAt(.{.x = 4, .y = 7}),
            grid.cellAt(.{.x = 5, .y = 7}),
            grid.cellAt(.{.x = 6, .y = 7}),
            grid.cellAt(.{.x = 5, .y = 8}),
        },
    );
    grid.print();

    try std.testing.expectEqual(7036, p1);
    // try std.testing.expectEqual(45,   p2);
}
