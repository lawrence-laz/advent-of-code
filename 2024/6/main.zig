const std = @import("std");

// https://adventofcode.com/2024/day/6

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn rotate(self: Vec2) Vec2 {
        return if (self.x == 1 and self.y == 0)
            .{ .x = 0, .y = 1 }
        else if (self.x == 0 and self.y == 1)
            .{ .x = -1, .y = 0 }
        else if (self.x == -1 and self.y == 0)
            .{ .x = 0, .y = -1 }
        else if (self.x == 0 and self.y == -1)
            .{ .x = 1, .y = 0 }
        else
            unreachable;
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
};

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !usize {
    const width = std.mem.indexOf(u8, input, "\n").?;
    const input_single_line = try allocator.alloc(u8, std.mem.replacementSize(u8, input, "\n", ""));
    defer allocator.free(input_single_line);
    _ = std.mem.replace(u8, input, "\n", "", input_single_line);
    const height = input.len / width;
    var grid: Grid = .{ .width = width, .height = height, .slice = input_single_line };
    const curr_index = std.mem.indexOf(u8, input_single_line, "^").?;
    const curr_x: usize = curr_index % grid.width;
    const curr_y: usize = curr_index / grid.width;
    var curr_pos: Vec2 = .{ .x = @intCast(curr_x), .y = @intCast(curr_y) };
    var dir: Vec2 = .{ .x = 0, .y = -1 };
    var next_pos = curr_pos;

    while (grid.get(next_pos)) |next_cell| {
        switch (next_cell) {
            '#' => {
                dir = dir.rotate();
                next_pos = curr_pos.add(dir);
            },
            '.', 'X', '^' => {
                curr_pos = next_pos;
                next_pos = curr_pos.add(dir);
                grid.set(curr_pos, 'X');
            },
            else => unreachable,
        }
    }

    return std.mem.count(u8, grid.slice, "X");
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(41, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(5461, result);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const width = std.mem.indexOf(u8, input, "\n").?;
    const input_single_line = try allocator.alloc(u8, std.mem.replacementSize(u8, input, "\n", ""));
    defer allocator.free(input_single_line);
    var new_obstruction_index: usize = 0;
    var potential_pos_count: usize = 0;
    var history = std.AutoHashMap(Vec2, Vec2).init(allocator);
    defer history.deinit();
    while (new_obstruction_index < input_single_line.len) : (new_obstruction_index += 1) {
        _ = std.mem.replace(u8, input, "\n", "", input_single_line);
        history.clearRetainingCapacity();
        const height = input.len / width;
        var grid: Grid = .{ .width = width, .height = height, .slice = input_single_line };
        const curr_index = std.mem.indexOf(u8, input_single_line, "^").?;
        const curr_x: usize = curr_index % grid.width;
        const curr_y: usize = curr_index / grid.width;
        var curr_pos: Vec2 = .{ .x = @intCast(curr_x), .y = @intCast(curr_y) };
        var dir: Vec2 = .{ .x = 0, .y = -1 };
        var next_pos = curr_pos;

        const new_obstruction_x: usize = new_obstruction_index % grid.width;
        const new_obstruction_y: usize = new_obstruction_index / grid.width;
        const new_obstruction_pos: Vec2 = .{ .x = @intCast(new_obstruction_x), .y = @intCast(new_obstruction_y) };
        grid.set(new_obstruction_pos, '#');

        while (grid.get(next_pos)) |next_cell| {
            switch (next_cell) {
                '#' => {
                    dir = dir.rotate();
                    next_pos = curr_pos.add(dir);
                },
                '.', 'X', '^' => {
                    curr_pos = next_pos;
                    if (history.get(curr_pos)) |history_dir| if (history_dir.eql(dir)) {
                        // Loop detected.
                        potential_pos_count += 1;
                        break;
                    };
                    try history.put(curr_pos, dir);
                    next_pos = curr_pos.add(dir);
                    grid.set(curr_pos, 'X');
                },
                else => unreachable,
            }
        }
    }

    return potential_pos_count;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(6, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(1836, result);
}
