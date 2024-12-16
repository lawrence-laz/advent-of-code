const std = @import("std");

// https://adventofcode.com/2024/day/16

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn mul(self: Vec2, number: i32) Vec2 {
        return .{ .x = self.x * number, .y = self.y * number };
    }

    pub fn eql(self: Vec2, other: Vec2) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Grid = struct {
    slice: []u8,
    width: usize,
    height: usize,

    const NeighboursIter = struct {
        center: Vec2,
        grid: *const Grid,
        index: usize,

        pub fn next(self: *NeighboursIter) ?Vec2 {
            const neighbour_pos = self.nextUnsafe() orelse return null;
            return if (self.grid.contains(neighbour_pos)) neighbour_pos else self.next();
        }

        pub fn nextUnsafe(self: *NeighboursIter) ?Vec2 {
            const neighbour_pos = switch (self.index) {
                0 => self.center.add(.{ .x = 1, .y = 0 }),
                1 => self.center.add(.{ .x = 0, .y = -1 }),
                2 => self.center.add(.{ .x = -1, .y = 0 }),
                3 => self.center.add(.{ .x = 0, .y = 1 }),
                else => return null,
            };
            self.index += 1;
            return neighbour_pos;
        }
    };

    fn print(self: @This()) void {
        var x: i32 = 0;
        var y: i32 = 0;
        while (y < self.height) : (y += 1) {
            x = 0;
            while (x < self.width) : (x += 1) {
                std.debug.print("{c}", .{self.get(.{ .x = x, .y = y }).?});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }

    fn neighbours(self: *const @This(), pos: Vec2) NeighboursIter {
        return .{ .center = pos, .grid = self, .index = 0 };
    }

    fn indexToPos(self: @This(), index: usize) Vec2 {
        return .{ .x = @intCast(index % self.width), .y = @intCast(index / self.width) };
    }

    fn get(self: @This(), pos: Vec2) ?u8 {
        if (pos.x < 0 or pos.x >= self.width or pos.y < 0 or pos.y >= self.height) {
            return null;
        }
        const y: usize = @intCast(pos.y);
        const x: usize = @intCast(pos.x);
        const i: usize = y * self.width + x;
        if (i < 0 or i >= self.slice.len) {
            return null;
        }
        return self.slice[i];
    }

    fn set(self: *@This(), pos: Vec2, value: u8) void {
        if (pos.x < 0 or pos.x >= self.width or pos.y < 0 or pos.y >= self.height) return;
        const y: usize = @intCast(pos.y);
        const x: usize = @intCast(pos.x);
        self.slice[y * self.width + x] = value;
    }

    fn contains(self: @This(), pos: Vec2) bool {
        return pos.x >= 0 and pos.x < self.width and pos.y >= 0 and pos.y < self.height;
    }
};

const Dir = enum { north, east, south, west };

fn getDir(from: Vec2, to: Vec2) Dir {
    return if (from.x < to.x)
        .east
    else if (to.x < from.x)
        .west
    else if (to.y < from.y)
        .north
    else if (from.y < to.y)
        .south
    else
        unreachable;
}

fn getTurnPrice(from: Dir, to: Dir) usize {
    if (from == .east and to == .east) return 0;
    if (from == .east and to == .north) return 1000;
    if (from == .east and to == .west) return 2000;
    if (from == .east and to == .south) return 1000;
    if (from == .north and to == .east) return 1000;
    if (from == .north and to == .north) return 0;
    if (from == .north and to == .west) return 1000;
    if (from == .north and to == .south) return 2000;
    if (from == .west and to == .east) return 2000;
    if (from == .west and to == .north) return 1000;
    if (from == .west and to == .west) return 0;
    if (from == .west and to == .south) return 1000;
    if (from == .south and to == .east) return 1000;
    if (from == .south and to == .north) return 2000;
    if (from == .south and to == .west) return 1000;
    if (from == .south and to == .south) return 0;
    unreachable;
}

const NavNode = struct {
    cost_so_far: usize,
    prev_pos: ?Vec2,
    dir: Dir,
};

const Result = struct {
    cost: usize,
    tiles: usize,
};

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !Result {
    const input_single_line = try allocator.alloc(u8, std.mem.replacementSize(u8, input, "\n", ""));
    defer allocator.free(input_single_line);
    const height = std.mem.replace(u8, input, "\n", "", input_single_line);
    const width = input_single_line.len / height;
    var grid: Grid = .{ .slice = input_single_line, .width = width, .height = height };
    const start_pos: Vec2 = grid.indexToPos(std.mem.indexOf(u8, grid.slice, "S").?);
    const end_pos: Vec2 = grid.indexToPos(std.mem.indexOf(u8, grid.slice, "E").?);

    var nav: std.AutoArrayHashMapUnmanaged(Vec2, std.ArrayListUnmanaged(NavNode)) = .{};
    defer nav.deinit(allocator);
    defer for (nav.values()) |*nodes| nodes.deinit(allocator);
    // const start_nav: NavNode = .{ .cost_so_far = 0, .prev_pos = null, .dir = .east };
    const start_nav = try nav.getOrPutValue(allocator, start_pos, .{});
    try start_nav.value_ptr.append(allocator, .{ .cost_so_far = 0, .prev_pos = null, .dir = .east });

    var to_walk: std.ArrayListUnmanaged(Vec2) = .{};
    defer to_walk.deinit(allocator);

    var start_neigbours = grid.neighbours(start_pos);
    while (start_neigbours.next()) |next_pos| {
        const next = grid.get(next_pos) orelse continue;
        if (next == '#') continue;
        try to_walk.append(allocator, next_pos);
        const dir = getDir(start_pos, next_pos);
        const next_nav: NavNode = .{
            .dir = dir,
            .cost_so_far = getTurnPrice(.east, dir) + 1,
            .prev_pos = start_pos,
        };
        var nav_nodes = try nav.getOrPutValue(allocator, next_pos, .{});
        if (nav_nodes.found_existing and
            nav_nodes.value_ptr.items.len > 0 and
            nav_nodes.value_ptr.items[0].cost_so_far > next_nav.cost_so_far)
        {
            nav_nodes.value_ptr.clearRetainingCapacity();
        }
        try nav_nodes.value_ptr.append(allocator, next_nav);
    }

    // var visited: std.ArrayListUnmanaged(Vec2) = .{};
    // try visited.append(allocator, start);

    while (to_walk.popOrNull()) |curr_pos| {
        const curr_nav = nav.get(curr_pos).?.items[0];
        var neighbours = grid.neighbours(curr_pos);
        while (neighbours.next()) |next_pos| {
            const next = grid.get(next_pos) orelse continue;
            if (next == '#') continue;
            const next_dir = getDir(curr_pos, next_pos);
            const next_price = getTurnPrice(curr_nav.dir, next_dir) + 1;
            const next_nav: NavNode = .{ .prev_pos = curr_pos, .dir = next_dir, .cost_so_far = curr_nav.cost_so_far + next_price };
            if (next_pos.x == 15 and next_pos.y == 7)
                std.log.debug("came to target from {any} with price {any}", .{ curr_pos, next_nav.cost_so_far });
            var nav_nodes = try nav.getOrPutValue(allocator, next_pos, .{});
            if (nav_nodes.found_existing and nav_nodes.value_ptr.items.len > 0) {
                if (next_pos.x == 15 and next_pos.y == 7)
                    std.log.debug("but best is {any}", .{nav_nodes.value_ptr.items[0].cost_so_far});
                if (nav_nodes.value_ptr.items[0].cost_so_far > next_nav.cost_so_far) {
                    nav_nodes.value_ptr.clearRetainingCapacity();
                    try nav_nodes.value_ptr.append(allocator, next_nav);
                } else if (nav_nodes.value_ptr.items[0].cost_so_far >= next_nav.cost_so_far - 1000) {
                    try nav_nodes.value_ptr.append(allocator, next_nav);
                }
                if (nav_nodes.value_ptr.items[0].cost_so_far >= next_nav.cost_so_far) {
                    if (next != 'E') {
                        try to_walk.append(allocator, next_pos);
                    }
                }
            } else {
                try nav_nodes.value_ptr.append(allocator, next_nav);
                if (next != 'E') {
                    try to_walk.append(allocator, next_pos);
                }
            }
        }
        // try visited.append(allocator, curr_pos);
        // try to_walk.append()
    }

    // var node = nav.get(end_pos).?;
    // while (node.prev_pos) |prev_pos| {
    //     node = nav.get(prev_pos).?;
    //     const char: u8 = switch (node.dir) {
    //         .east => '>',
    //         .north => '^',
    //         .west => '<',
    //         .south => 'v',
    //     };
    //     grid.set(prev_pos, char);
    // }

    var tiles: std.AutoArrayHashMapUnmanaged(Vec2, void) = .{};
    defer tiles.deinit(allocator);
    var to_visit: std.ArrayListUnmanaged(Vec2) = .{};
    defer to_visit.deinit(allocator);
    try to_visit.append(allocator, end_pos);
    while (to_visit.popOrNull()) |pos| {
        try tiles.put(allocator, pos, {});
        const pos_nav = nav.get(pos).?;
        if (pos.x == 15 and pos.y == 7) std.debug.print("\n!!! {any} !!!\n", .{pos_nav.items.len});
        for (pos_nav.items) |next_nav| {
            if (next_nav.prev_pos) |next_pos| {
                try to_visit.append(allocator, next_pos);
            }
        }
    }

    // while (node.prev_pos) |prev_pos| {
    for (tiles.keys()) |pos| {
        grid.set(pos, 'O');
    }
    grid.print();

    return .{ .cost = nav.get(end_pos).?.items[0].cost_so_far, .tiles = tiles.count() };
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(11048, result.cost);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(99460, result.cost);
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(64, result.tiles);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(123, result.tiles);
}
