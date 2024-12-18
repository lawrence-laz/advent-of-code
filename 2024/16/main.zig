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

fn getTurnCost(from: Dir, to: Dir) usize {
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

const Path = struct {
    cost: usize,
    positions: []Vec2,
};

const Result = struct {
    cheapest_path_cost: usize,
    cheapest_path_tiles: usize,
};

const Edge = struct {
    from: Vec2,
    to: Vec2,
};

fn findEnd(
    allocator: std.mem.Allocator,
    grid: Grid,
    pos: Vec2,
    dir: Dir,
    came_from: *std.AutoArrayHashMapUnmanaged(Vec2, void),
    total_cost: usize,
    paths: *std.ArrayListUnmanaged(Path),
    visited: *std.AutoHashMapUnmanaged(Edge, usize),
) !void {
    // std.debug.print("{any}\n", .{pos});
    try came_from.put(allocator, pos, {});
    const char = grid.get(pos) orelse return;
    if (char == 'E') {
        try paths.append(allocator, .{
            .cost = total_cost,
            .positions = try allocator.dupe(Vec2, came_from.keys()),
        });
    }
    var neighbours = grid.neighbours(pos);
    while (neighbours.next()) |next_pos| {
        const new_dir = getDir(pos, next_pos);
        const new_cost = getTurnCost(dir, new_dir) + 1;
        if (visited.get(.{ .from = pos, .to = next_pos })) |prev_cost| {
            if (prev_cost < new_cost) continue;
        }
        if (came_from.contains(next_pos)) continue;
        const next_char = grid.get(next_pos) orelse continue;
        if (next_char == '#') continue;
        try visited.put(allocator, .{ .from = pos, .to = next_pos }, new_cost);
        try findEnd(
            allocator,
            grid,
            next_pos,
            new_dir,
            came_from,
            total_cost + new_cost,
            paths,
            visited,
        );
    }
    _ = came_from.pop();
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const input_single_line = try arena.allocator().alloc(u8, std.mem.replacementSize(u8, input, "\n", ""));
    defer arena.allocator().free(input_single_line);
    const height = std.mem.replace(u8, input, "\n", "", input_single_line);
    const width = input_single_line.len / height;
    var grid: Grid = .{ .slice = input_single_line, .width = width, .height = height };
    const start_pos: Vec2 = grid.indexToPos(std.mem.indexOf(u8, grid.slice, "S").?);

    var came_from: std.AutoArrayHashMapUnmanaged(Vec2, void) = .{};
    var paths: std.ArrayListUnmanaged(Path) = .{};
    var visited: std.AutoHashMapUnmanaged(Edge, usize) = .{};
    try findEnd(arena.allocator(), grid, start_pos, .east, &came_from, 0, &paths, &visited);

    var cheapest_path_cost: usize = std.math.maxInt(usize);
    for (paths.items) |path| {
        if (cheapest_path_cost > path.cost) cheapest_path_cost = path.cost;
    }

    var cheapest_path_tiles: std.AutoHashMapUnmanaged(Vec2, void) = .{};
    for (paths.items) |path| {
        if (path.cost == cheapest_path_cost) {
            for (path.positions) |pos| {
                try cheapest_path_tiles.put(arena.allocator(), pos, {});
            }
        }
    }

    return .{ .cheapest_path_cost = cheapest_path_cost, .cheapest_path_tiles = cheapest_path_tiles.count() };

    // while (node.prev_pos) |prev_pos| {
    // for (tiles.keys()) |pos| {
    //     grid.set(pos, 'O');
    // }
    // grid.print();
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(11048, result.cheapest_path_cost);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(99460, result.cheapest_path_cost);
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(64, result.cheapest_path_tiles);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(123, result.cheapest_path_tiles);
}
