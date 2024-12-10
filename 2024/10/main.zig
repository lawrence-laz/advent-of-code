const std = @import("std");

// https://adventofcode.com/2024/day/10
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
            const neighbour_pos = switch (self.index) {
                0 => self.center.add(.{ .x = 1, .y = 0 }),
                1 => self.center.add(.{ .x = 0, .y = -1 }),
                2 => self.center.add(.{ .x = -1, .y = 0 }),
                3 => self.center.add(.{ .x = 0, .y = 1 }),
                else => return null,
            };
            self.index += 1;
            return if (self.grid.contains(neighbour_pos)) neighbour_pos else self.next();
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
};

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !usize {
    const width: usize = std.mem.indexOf(u8, input, "\n").?;
    const input_single_line: []u8 = try allocator.alloc(u8, std.mem.replacementSize(u8, input, "\n", ""));
    defer allocator.free(input_single_line);
    const height = std.mem.replace(u8, input, "\n", "", input_single_line);
    const grid: Grid = .{ .slice = input_single_line, .width = width, .height = height };

    var trailheads_score_sum: usize = 0;
    var peak_per_path: std.ArrayListUnmanaged(Vec2) = .{};
    defer peak_per_path.deinit(allocator);
    for (input_single_line, 0..) |value, i| {
        peak_per_path.clearRetainingCapacity();
        const pos: Vec2 = grid.indexToPos(i);
        if (value != '0') continue;
        try findPathToPeak(allocator, pos, &grid, &peak_per_path);
        var unique_peaks: std.AutoHashMapUnmanaged(Vec2, void) = .{};
        defer unique_peaks.deinit(allocator);
        for (peak_per_path.items) |peak| try unique_peaks.put(allocator, peak, {});
        trailheads_score_sum += unique_peaks.count();
    }
    return trailheads_score_sum;
}

fn findPathToPeak(
    allocator: std.mem.Allocator,
    start_pos: Vec2,
    grid: *const Grid,
    peak_per_path: *std.ArrayListUnmanaged(Vec2),
) !void {
    var path: std.AutoArrayHashMapUnmanaged(Vec2, void) = .{};
    defer path.deinit(allocator);
    var to_visit: std.ArrayListUnmanaged(Vec2) = .{};
    defer to_visit.deinit(allocator);
    try to_visit.append(allocator, start_pos);
    while (to_visit.popOrNull()) |pos| {
        try path.put(allocator, pos, {});
        const height = grid.get(pos).?;
        if (height == '9') {
            try peak_per_path.append(allocator, pos);
        } else {
            var neighbours = grid.neighbours(pos);
            while (neighbours.next()) |neighbour| {
                if (path.contains(neighbour)) continue;
                if (grid.get(neighbour).? != height + 1) continue;
                try to_visit.append(allocator, neighbour);
            }
        }
        _ = path.orderedRemove(pos);
    }
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(36, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(646, result);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const width: usize = std.mem.indexOf(u8, input, "\n").?;
    const input_single_line: []u8 = try allocator.alloc(u8, std.mem.replacementSize(u8, input, "\n", ""));
    defer allocator.free(input_single_line);
    const height = std.mem.replace(u8, input, "\n", "", input_single_line);
    const grid: Grid = .{ .slice = input_single_line, .width = width, .height = height };
    var trailheads_score_sum: usize = 0;
    var peak_per_path: std.ArrayListUnmanaged(Vec2) = .{};
    defer peak_per_path.deinit(allocator);
    for (input_single_line, 0..) |value, i| {
        peak_per_path.clearRetainingCapacity();
        const pos: Vec2 = grid.indexToPos(i);
        if (value != '0') continue;
        try findPathToPeak(allocator, pos, &grid, &peak_per_path);
        trailheads_score_sum += peak_per_path.items.len;
    }
    return trailheads_score_sum;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(81, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(1494, result);
}
