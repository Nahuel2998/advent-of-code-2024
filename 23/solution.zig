const std = @import("std");

const Computer    = [2]u8;
const Triplet     = [3]Computer;
const Connections = struct {
    allocator: std.mem.Allocator,
    conns:     std.AutoHashMapUnmanaged(Computer, std.AutoArrayHashMapUnmanaged(Computer, void)),

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
                        const lessThan = struct {
                            fn lessThan(_: void, lhs: Computer, rhs: Computer) bool {
                                return std.mem.lessThan(u8, &lhs, &rhs);
                            }
                        }.lessThan;
                        std.mem.sortUnstable(Computer, &key, {}, lessThan);
                        try res.put(self.allocator, key, {});
                    }
                }
            }
        }

        return res.keys();
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

pub fn countChiefHistorianTriplets(triplets: []Triplet) u32 {
    var res: u32 = 0;
    for (triplets) |triplet| {
        for (triplet) |c| {
            if (c[0] == 't') {
                res += 1;
                std.debug.print("{s},{s},{s}\n", .{ triplet[0], triplet[1], triplet[2] });
                break;
            }
        }
    }
    return res;
}

pub fn main(init: std.process.Init) !void {
    const input = @embedFile("input");

    const conns = try Connections.init(init.arena.allocator(), input);
    conns.print();

    const triplets = try conns.triplets();
    std.debug.print("{}\n", .{ countChiefHistorianTriplets(triplets) });
}

test "example" {
    const input = @embedFile("example");

    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();

    const conns = try Connections.init(arena.allocator(), input);
    conns.print();

    const triplets = try conns.triplets();
    try std.testing.expectEqual(7, countChiefHistorianTriplets(triplets));
}
