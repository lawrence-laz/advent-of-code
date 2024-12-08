const std = @import("std");

// https://adventofcode.com/2024/day/8

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
    const single_line = try allocator.alloc(u8, std.mem.replacementSize(u8, input, "\n", ""));
    defer allocator.free(single_line);
    const height: usize = @intCast(std.mem.replace(u8, input, "\n", "", single_line));
    const width: usize = single_line.len / height;
    var grid: Grid = .{ .slice = single_line, .width = width, .height = height };

    var frequencies: std.AutoArrayHashMapUnmanaged(u8, std.ArrayListUnmanaged(Vec2)) = .{};
    defer {
        for (frequencies.values()) |*frequency| {
            frequency.deinit(allocator);
        }
        frequencies.deinit(allocator);
    }
    for (single_line, 0..) |item, i| {
        const pos: Vec2 = .{ .x = @intCast(i % width), .y = @intCast(i / width) };

        if (item == '.') continue;

        var positions: *std.ArrayListUnmanaged(Vec2) = blk: {
            if (frequencies.getPtr(item)) |positions| break :blk positions;
            try frequencies.put(allocator, item, .{});
            break :blk frequencies.getPtr(item).?;
        };

        try positions.append(allocator, pos);
    }

    var antenodes: std.AutoHashMapUnmanaged(Vec2, void) = .{};
    defer antenodes.deinit(allocator);
    for (frequencies.keys()) |frequency| {
        const positions = frequencies.getPtr(frequency).?;
        var position_index_1: usize = 0;
        var position_index_2: usize = 1;
        while (position_index_1 < positions.items.len) {
            while (position_index_2 < positions.items.len) {
                const freq_pos_1 = positions.items[position_index_1];
                const freq_pos_2 = positions.items[position_index_2];

                const antenode_pos_1 = freq_pos_1.add(freq_pos_2.sub(freq_pos_1).mul(2));
                const antenode_pos_2 = freq_pos_2.add(freq_pos_1.sub(freq_pos_2).mul(2));

                if (grid.contains(antenode_pos_1)) {
                    try antenodes.put(allocator, antenode_pos_1, {});
                }
                if (grid.contains(antenode_pos_2)) {
                    try antenodes.put(allocator, antenode_pos_2, {});
                }
                position_index_2 += 1;
            }
            position_index_1 += 1;
            position_index_2 = position_index_1 + 1;
        }
    }

    return antenodes.count();
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(14, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(228, result);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const single_line = try allocator.alloc(u8, std.mem.replacementSize(u8, input, "\n", ""));
    defer allocator.free(single_line);
    const height: usize = @intCast(std.mem.replace(u8, input, "\n", "", single_line));
    const width: usize = single_line.len / height;
    var grid: Grid = .{ .slice = single_line, .width = width, .height = height };

    var frequencies: std.AutoArrayHashMapUnmanaged(u8, std.ArrayListUnmanaged(Vec2)) = .{};
    defer {
        for (frequencies.values()) |*frequency| {
            frequency.deinit(allocator);
        }
        frequencies.deinit(allocator);
    }
    for (single_line, 0..) |item, i| {
        const pos: Vec2 = .{ .x = @intCast(i % width), .y = @intCast(i / width) };

        if (item == '.') continue;

        var positions: *std.ArrayListUnmanaged(Vec2) = blk: {
            if (frequencies.getPtr(item)) |positions| break :blk positions;
            try frequencies.put(allocator, item, .{});
            break :blk frequencies.getPtr(item).?;
        };

        try positions.append(allocator, pos);
    }

    var antenodes: std.AutoHashMapUnmanaged(Vec2, void) = .{};
    defer antenodes.deinit(allocator);
    for (frequencies.keys()) |frequency| {
        const positions = frequencies.getPtr(frequency).?;
        var position_index_1: usize = 0;
        var position_index_2: usize = 1;
        while (position_index_1 < positions.items.len) {
            while (position_index_2 < positions.items.len) {
                var freq_pos_1 = positions.items[position_index_1];
                var freq_pos_2 = positions.items[position_index_2];
                const period_1 = freq_pos_2.sub(freq_pos_1);
                const period_2 = freq_pos_1.sub(freq_pos_2);
                while (grid.contains(freq_pos_1)) {
                    try antenodes.put(allocator, freq_pos_1, {});
                    freq_pos_1 = freq_pos_1.add(period_1);
                }
                while (grid.contains(freq_pos_2)) {
                    try antenodes.put(allocator, freq_pos_2, {});
                    freq_pos_2 = freq_pos_2.add(period_2);
                }
                position_index_2 += 1;
            }
            position_index_1 += 1;
            position_index_2 = position_index_1 + 1;
        }
    }

    return antenodes.count();
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(34, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(766, result);
}
