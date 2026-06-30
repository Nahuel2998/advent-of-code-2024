const std = @import("std");

const ComputerSet = std.AutoArrayHashMapUnmanaged(Computer, void);
const Computer    = [2]u8;
const Triplet     = [3]Computer;
const Connections = struct {
    allocator: std.mem.Allocator,
    conns:     std.AutoHashMapUnmanaged(Computer, ComputerSet),

    pub fn init(allocator: std.mem.Allocator, input: []const u8) !Connections {
        var self: Connections = .{
            .allocator = allocator,
            .conns     = .empty,
        };

        var i: usize = 0;
        while (i < input.len) {
            const c1: Computer = .{ input[i  ], input[i+1] };
            const c2: Computer = .{ input[i+3], input[i+4] };

            var  cons1 = try self.conns.getOrPut(self.allocator, c1);
            if (!cons1.found_existing) cons1.value_ptr.* = .empty;
            try  cons1.value_ptr.put(self.allocator, c2, {});

            var  cons2 = try self.conns.getOrPut(self.allocator, c2);
            if (!cons2.found_existing) cons2.value_ptr.* = .empty;
            try  cons2.value_ptr.put(self.allocator, c1, {});

            i += 6;
        }

        return self;
    }

    pub fn triplets(self: Connections) ![]Triplet {
        var res: std.AutoArrayHashMapUnmanaged(Triplet, void) = .empty;

        var it = self.conns.iterator();
        while (it.next()) |conn| {
            const c1     = conn.key_ptr.*;
            const others = conn.value_ptr.keys();
            for (others, 0..) |c2, i| {
                for (others[(i + 1)..]) |c3| {
                    if (self.conns.get(c2).?.contains(c3)) {
                        var key = [_]Computer{ c1, c2, c3 };
                        std.mem.sortUnstable(Computer, &key, {}, computerLessThan);
                        try res.put(self.allocator, key, {});
                    }
                }
            }
        }

        return res.keys();
    }

    // NOTE: I'm not sure this works with all inputs
    //       It's the first I thought of and it works with my input
    //       I wonder if ordering can screw it up...?
    pub fn groups(self: Connections) ![]ComputerSet {
        var res: std.ArrayList(ComputerSet) = .empty;

        var it = self.conns.iterator();
        while (it.next()) |conn| {
            const c1     = conn.key_ptr.*;
            const others = conn.value_ptr.keys();
            for (others) |c2| {
                var found = false;
                next_group: for (res.items) |*grp| {
                    if (!grp.contains(c1))                 continue;
                    if ( grp.contains(c2)) { found = true; continue; }

                    for (grp.keys()) |e| {
                        if (!self.conns.get(e).?.contains(c2)) {
                            continue :next_group;
                        }
                    }
                    found = true;
                    try grp.put(self.allocator, c2, {});
                }
                if (!found) {
                    var newgrp: ComputerSet = .empty;
                    try newgrp.put(self.allocator, c1, {});
                    try newgrp.put(self.allocator, c2, {});
                    try res.append(self.allocator, newgrp);
                }
            }
        }

        return res.items;
    }

    pub fn print(self: Connections) void {
        var it = self.conns.iterator();
        while (it.next()) |conn| {
            std.debug.print("{s}: ", .{ conn.key_ptr });
            for (conn.value_ptr.keys()) |other| {
                std.debug.print("{s}, ", .{other});
            }
            std.debug.print("\n", .{});
        }
    }
};

fn computerLessThan(_: void, lhs: Computer, rhs: Computer) bool {
    return std.mem.lessThan(u8, &lhs, &rhs);
}

pub fn countChiefHistorianTriplets(triplets: []Triplet) u32 {
    var res: u32 = 0;
    for (triplets) |triplet| {
        for (triplet) |c| {
            if (c[0] == 't') {
                res += 1;
                break;
            }
        }
    }
    return res;
}

pub fn findLargestGroup(groups: []ComputerSet) []Computer {
    var maxlen: usize = 0;
    var res: ComputerSet = undefined;
    for (groups) |grp| {
        const glen = grp.count();
        if (glen > maxlen) {
            res    = grp;
            maxlen = glen;
        }
    }
    return res.keys();
}

pub fn part2(allocator: std.mem.Allocator, groups: []ComputerSet) ![]u8 {
    var res: std.ArrayList(u8) = .empty;

    const largestGroup = findLargestGroup(groups);
    std.mem.sortUnstable(Computer, largestGroup, {}, computerLessThan);
    for (largestGroup) |c| {
        try res.appendSlice(allocator, &c);
        try res.append(allocator, ',');
    }

    return res.items[0..res.items.len - 1];
}

pub fn main(init: std.process.Init) !void {
    const input     = @embedFile("input");
    const allocator = init.arena.allocator();

    const conns = try Connections.init(allocator, input);
    conns.print();

    const triplets = try conns.triplets();
    std.debug.print("Part 1: {}\n", .{ countChiefHistorianTriplets(triplets) });

    const groups = try conns.groups();
    std.debug.print("Part 2: {s}\n", .{ try part2(allocator, groups) });
}

test "example" {
    const input = @embedFile("example");

    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();

    const conns = try Connections.init(arena.allocator(), input);
    conns.print();

    const triplets = try conns.triplets();
    try std.testing.expectEqual(7, countChiefHistorianTriplets(triplets));

    const groups = try conns.groups();
    try std.testing.expectEqualStrings("co,de,ka,ta", try part2(arena.allocator(), groups));
}
