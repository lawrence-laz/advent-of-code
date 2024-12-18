const std = @import("std");

// https://adventofcode.com/2024/day/18

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
};

fn solvePart1(
    allocator: std.mem.Allocator,
    input: []const u8,
    grid: *Grid,
    take_count: usize,
) !usize {
    var took_count: usize = 0;
    var lines = std.mem.tokenize(u8, input, "\n");
    while (lines.next()) |line| {
        if (took_count == take_count) break;
        took_count += 1;
        var coords = std.mem.split(u8, line, ",");
        grid.set(.{
            .x = try std.fmt.parseInt(i32, coords.next().?, 10),
            .y = try std.fmt.parseInt(i32, coords.next().?, 10),
        }, '#');
    }

    const start_pos: Vec2 = .{ .x = 0, .y = 0 };
    const end_pos: Vec2 = .{ .x = @intCast(grid.width - 1), .y = @intCast(grid.height - 1) };

    const Frontier = struct {
        pos: Vec2,
        cost: usize,

        fn lessThan(context: void, a: @This(), b: @This()) bool {
            _ = context;
            return a.cost > b.cost;
        }
    };

    var frontiers: std.ArrayListUnmanaged(Frontier) = .{};
    defer frontiers.deinit(allocator);
    try frontiers.append(allocator, .{ .pos = start_pos, .cost = 0 });

    var came_from: std.AutoHashMapUnmanaged(Vec2, ?Vec2) = .{};
    defer came_from.deinit(allocator);
    try came_from.put(allocator, start_pos, null);

    var cost_so_far: std.AutoHashMapUnmanaged(Vec2, usize) = .{};
    defer cost_so_far.deinit(allocator);
    try cost_so_far.put(allocator, start_pos, 0);

    search: while (frontiers.popOrNull()) |frontier| {
        var neighbours_pos = grid.neighbours(frontier.pos);
        while (neighbours_pos.next()) |neighbour_pos| {
            if (grid.get(neighbour_pos).? == '#') continue;

            const new_cost = cost_so_far.get(frontier.pos).? + 1;
            if (!cost_so_far.contains(neighbour_pos) or new_cost < cost_so_far.get(neighbour_pos).?) {
                try cost_so_far.put(allocator, neighbour_pos, new_cost);
                try frontiers.append(allocator, .{ .pos = neighbour_pos, .cost = new_cost });
                std.mem.sort(Frontier, frontiers.items, {}, Frontier.lessThan);
                try came_from.put(allocator, neighbour_pos, frontier.pos);
                if (neighbour_pos.eql(end_pos)) break :search;
            }
        }
    }

    var path_length: usize = 0;
    var pos: Vec2 = end_pos;
    while (came_from.get(pos)) |prev_pos| {
        grid.set(pos, 'O');
        if (prev_pos == null) break;
        pos = prev_pos.?;
        path_length += 1;
    }

    return path_length;
}

test "example input part1" {
    var cells: [49]u8 = .{'.'} ** 49;
    var grid: Grid = .{ .slice = &cells, .width = 7, .height = 7 };
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input, &grid, 12);
    try std.testing.expectEqual(22, result);
}

test "real input part1" {
    var cells: [5041]u8 = .{'.'} ** 5041;
    var grid: Grid = .{ .slice = &cells, .width = 71, .height = 71 };
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input, &grid, 1024);
    try std.testing.expectEqual(248, result);
}

fn solvePart2(
    allocator: std.mem.Allocator,
    input: []const u8,
    grid: *Grid,
) !Vec2 {
    var take_count: usize = 0;
    while (true) {
        var took_count: usize = 0;
        var lines = std.mem.tokenize(u8, input, "\n");
        var last_corrupted_pos: Vec2 = .{ .x = 0, .y = 0 };
        while (lines.next()) |line| {
            if (took_count == take_count) break;
            took_count += 1;
            var coords = std.mem.split(u8, line, ",");
            last_corrupted_pos = .{
                .x = try std.fmt.parseInt(i32, coords.next().?, 10),
                .y = try std.fmt.parseInt(i32, coords.next().?, 10),
            };
            grid.set(last_corrupted_pos, '#');
        }

        const start_pos: Vec2 = .{ .x = 0, .y = 0 };
        const end_pos: Vec2 = .{ .x = @intCast(grid.width - 1), .y = @intCast(grid.height - 1) };

        const Frontier = struct {
            pos: Vec2,
            cost: usize,

            fn lessThan(context: void, a: @This(), b: @This()) bool {
                _ = context;
                return a.cost > b.cost;
            }
        };

        var frontiers: std.ArrayListUnmanaged(Frontier) = .{};
        defer frontiers.deinit(allocator);
        try frontiers.append(allocator, .{ .pos = start_pos, .cost = 0 });

        var came_from: std.AutoHashMapUnmanaged(Vec2, ?Vec2) = .{};
        defer came_from.deinit(allocator);
        try came_from.put(allocator, start_pos, null);

        var cost_so_far: std.AutoHashMapUnmanaged(Vec2, usize) = .{};
        defer cost_so_far.deinit(allocator);
        try cost_so_far.put(allocator, start_pos, 0);

        search: while (frontiers.popOrNull()) |frontier| {
            var neighbours_pos = grid.neighbours(frontier.pos);
            while (neighbours_pos.next()) |neighbour_pos| {
                if (grid.get(neighbour_pos).? == '#') continue;

                const new_cost = cost_so_far.get(frontier.pos).? + 1;
                if (!cost_so_far.contains(neighbour_pos) or new_cost < cost_so_far.get(neighbour_pos).?) {
                    try cost_so_far.put(allocator, neighbour_pos, new_cost);
                    try frontiers.append(allocator, .{ .pos = neighbour_pos, .cost = new_cost });
                    std.mem.sort(Frontier, frontiers.items, {}, Frontier.lessThan);
                    try came_from.put(allocator, neighbour_pos, frontier.pos);
                    if (neighbour_pos.eql(end_pos)) break :search;
                }
            }
        }

        var path_length: usize = 0;
        var pos: Vec2 = end_pos;
        while (came_from.get(pos)) |prev_pos| {
            grid.set(pos, 'O');
            if (prev_pos == null) break;
            pos = prev_pos.?;
            path_length += 1;
        }

        if (path_length > 0) {
            // Path is not blocked yet.
            take_count += 1;
            continue;
        }

        return last_corrupted_pos;
    }
}

test "example input part2" {
    var cells: [49]u8 = .{'.'} ** 49;
    var grid: Grid = .{ .slice = &cells, .width = 7, .height = 7 };
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(std.testing.allocator, input, &grid);
    try std.testing.expectEqual(6, result.x);
    try std.testing.expectEqual(1, result.y);
}

test "real input part2" {
    var cells: [5041]u8 = .{'.'} ** 5041;
    var grid: Grid = .{ .slice = &cells, .width = 71, .height = 71 };
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input, &grid);
    try std.testing.expectEqual(32, result.x);
    try std.testing.expectEqual(55, result.y);
}
