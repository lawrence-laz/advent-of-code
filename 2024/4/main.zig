const std = @import("std");

// https://adventofcode.com/2024/day/4

const Direction = enum {
    w_to_e,
    e_to_w,
    n_to_s,
    s_to_n,
    nw_to_se,
    se_to_nw,
    sw_to_ne,
    ne_to_sw,
};

fn GridLinesIter(comptime T: type) type {
    return struct {
        input: []const T,
        direction: Direction,
        width: usize,
        height: usize,
        index: usize,

        pub fn init(input: []const T, width: usize) @This() {
            const height = input.len / width;
            return .{
                .input = input,
                .direction = .w_to_e,
                .width = width,
                .height = height,
                .index = 0,
            };
        }

        pub fn next(self: *@This(), buf: []T) ?[]T {
            if (self.tryGetLine(buf)) |line| {
                return line;
            }
            return null;
        }

        pub fn reset(self: *@This()) void {
            self.index = 0;
        }

        fn tryGetLine(self: *@This(), buf: []T) ?[]T {
            var buf_index: usize = 0;
            switch (self.direction) {
                .w_to_e => if (self.index < self.height) {
                    const y = self.index;
                    self.index += 1;
                    var x: usize = 0;
                    while (x < self.width) : (x += 1) {
                        const next_index = y * self.width + x;
                        if (next_index < self.input.len) buf[buf_index] = self.input[next_index] else return null;
                        buf_index += 1;
                    }
                    return buf[0..buf_index];
                },
                .e_to_w => if (self.index < self.height) {
                    const y = self.index;
                    self.index += 1;
                    var x: usize = self.width - 1;
                    while (x >= 0) : (x -= 1) {
                        const next_index = y * self.width + x;
                        if (next_index < self.input.len) buf[buf_index] = self.input[next_index] else return null;
                        buf_index += 1;
                        if (x == 0) break;
                    }
                    return buf[0..buf_index];
                },
                .n_to_s => if (self.index < self.width) {
                    const x = self.index;
                    self.index += 1;
                    var y: usize = 0;
                    while (y < self.height) : (y += 1) {
                        const next_index = y * self.width + x;
                        if (next_index < self.input.len) buf[buf_index] = self.input[next_index] else return null;
                        buf_index += 1;
                    }
                    return buf[0..buf_index];
                },
                .s_to_n => if (self.index < self.width) {
                    const x = self.index;
                    self.index += 1;
                    var y: usize = self.height - 1;
                    while (y >= 0) : (y -= 1) {
                        const next_index = y * self.width + x;
                        if (next_index < self.input.len) buf[buf_index] = self.input[next_index] else return null;
                        buf_index += 1;
                        if (y == 0) break;
                    }
                    return buf[0..buf_index];
                },
                .se_to_nw => if (self.index <= self.width + self.height - 2) {
                    var x: usize = 0;
                    while (x <= self.index) : (x += 1) {
                        const y = self.index - x;
                        if (y < self.height and x < self.width) {
                            buf[buf_index] = self.input[y * self.width + (self.width - x - 1)];
                            buf_index += 1;
                        }
                    }
                    self.index += 1;
                    return buf[0..buf_index];
                },
                .ne_to_sw => if (self.index <= self.width + self.height - 2) {
                    var x: usize = 0;
                    while (x <= self.index) : (x += 1) {
                        const y = self.index - x;
                        if (y < self.height and x < self.width) {
                            buf[buf_index] = self.input[(self.height - y - 1) * self.width + (self.width - x - 1)];
                            buf_index += 1;
                        }
                    }
                    self.index += 1;
                    return buf[0..buf_index];
                },
                .nw_to_se => if (self.index <= self.width + self.height - 2) {
                    var x: usize = 0;
                    while (x <= self.index) : (x += 1) {
                        const y = self.index - x;
                        if (y < self.height and x < self.width) {
                            buf[buf_index] = self.input[(self.height - y - 1) * self.width + x];
                            buf_index += 1;
                        }
                    }
                    self.index += 1;
                    return buf[0..buf_index];
                },
                .sw_to_ne => if (self.index <= self.width + self.height - 2) {
                    var x: usize = 0;
                    while (x <= self.index) : (x += 1) {
                        const y = self.index - x;
                        if (y < self.height and x < self.width) {
                            buf[buf_index] = self.input[y * self.width + x];
                            buf_index += 1;
                        }
                    }
                    self.index += 1;
                    return buf[0..buf_index];
                },
            }
            return null;
        }
    };
}

pub fn solvePart1(allocator: std.mem.Allocator, input_lines: []const u8) !usize {
    const width = std.mem.indexOf(u8, input_lines, "\n").?;
    const input = try allocator.alloc(u8, std.mem.replacementSize(u8, input_lines, "\n", ""));
    defer allocator.free(input);
    _ = std.mem.replace(u8, input_lines, "\n", "", input);
    var iter = GridLinesIter(u8).init(input, width);
    var buf: [140]u8 = undefined;
    var xmas_count: usize = 0;
    for (std.meta.tags(Direction)) |direction| {
        iter.reset();
        iter.direction = direction;
        while (iter.next(&buf)) |line| {
            xmas_count += std.mem.count(u8, line, "XMAS");
        }
    }
    return xmas_count;
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(18, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(2578, result);
}

const Grid = struct {
    slice: []const u8,
    width: usize,
    height: usize,

    fn get(self: @This(), x: usize, y: usize) ?u8 {
        if (x < 0 or x >= self.width or y < 0 or y >= self.height) return null;
        const i: usize = y * self.width + x;
        if (i < 0 or i >= self.slice.len) return null;
        return self.slice[i];
    }
};

fn solvePart2(allocator: std.mem.Allocator, input_lines: []const u8) !u32 {
    const width = std.mem.indexOf(u8, input_lines, "\n").?;
    const input = try allocator.alloc(u8, std.mem.replacementSize(u8, input_lines, "\n", ""));
    defer allocator.free(input);
    _ = std.mem.replace(u8, input_lines, "\n", "", input);
    const height = input.len / width;
    const grid: Grid = .{ .width = width, .height = height, .slice = input };

    var result: u32 = 0;
    var x: usize = 1;
    var y: usize = 1;
    while (y < height) : (y += 1) {
        x = 1;
        while (x < width) : (x += 1) {
            const mas_leaning_left = grid.get(x - 1, y - 1) == 'M' and grid.get(x, y) == 'A' and grid.get(x + 1, y + 1) == 'S' or
                grid.get(x - 1, y - 1) == 'S' and grid.get(x, y) == 'A' and grid.get(x + 1, y + 1) == 'M';
            const mas_leaning_right = grid.get(x + 1, y - 1) == 'M' and grid.get(x, y) == 'A' and grid.get(x - 1, y + 1) == 'S' or
                grid.get(x + 1, y - 1) == 'S' and grid.get(x, y) == 'A' and grid.get(x - 1, y + 1) == 'M';
            if (mas_leaning_left and mas_leaning_right) result += 1;
        }
    }

    return result;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(9, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(1972, result);
}
