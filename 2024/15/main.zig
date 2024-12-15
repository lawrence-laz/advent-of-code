const std = @import("std");

// https://adventofcode.com/2024/day/15

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
            const neighbour_pos = self.nextUnsafe();
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

    fn move(self: *@This(), from: Vec2, dir: Vec2) bool {
        const to = from.add(dir);
        if (self.get(to)) |target| {
            const success = switch (target) {
                '.' => true,
                '#' => false,
                '@' => true,
                'O' => self.move(to, dir),
                '[' => self.move(to, dir) and (dir.y == 0 or self.move(to.add(.{ .x = 1, .y = 0 }), dir)),
                ']' => self.move(to, dir) and (dir.y == 0 or self.move(to.add(.{ .x = -1, .y = 0 }), dir)),
                else => {
                    std.log.err("target={c}", .{target});
                    unreachable;
                },
            };
            if (success) {
                const source = self.get(from).?;
                self.set(to, source);
                self.set(from, '.');
            }
            return success;
        } else return false;
    }

    fn moveCheck(self: *@This(), from: Vec2, dir: Vec2) bool {
        const to = from.add(dir);
        if (self.get(to)) |target| {
            const success = switch (target) {
                '.' => true,
                '#' => false,
                '@' => true,
                'O' => self.moveCheck(to, dir),
                '[' => self.moveCheck(to, dir) and (dir.y == 0 or self.moveCheck(to.add(.{ .x = 1, .y = 0 }), dir)),
                ']' => self.moveCheck(to, dir) and (dir.y == 0 or self.moveCheck(to.add(.{ .x = -1, .y = 0 }), dir)),
                else => {
                    std.log.err("target={c}", .{target});
                    unreachable;
                },
            };
            return success;
        } else return false;
    }
};

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !i32 {
    var map_and_movements_strings = std.mem.tokenizeSequence(u8, input, "\n\n");
    const map_string = map_and_movements_strings.next().?;
    const movements_string = map_and_movements_strings.next().?;
    const map_single_line = try allocator.alloc(u8, std.mem.replacementSize(u8, map_string, "\n", ""));
    defer allocator.free(map_single_line);
    const height = std.mem.replace(u8, map_string, "\n", "", map_single_line) + 1;
    const width = map_single_line.len / height;
    var grid: Grid = .{ .slice = map_single_line, .width = width, .height = height };
    const movements_single_line = try allocator.alloc(u8, std.mem.replacementSize(u8, movements_string, "\n", ""));
    defer allocator.free(movements_single_line);
    _ = std.mem.replace(u8, movements_string, "\n", "", movements_single_line);
    var robot_pos = grid.indexToPos(std.mem.indexOf(u8, map_single_line, "@").?);
    var movement_index: usize = 0;
    while (movement_index < movements_single_line.len) : (movement_index += 1) {
        const dir: Vec2 = switch (movements_single_line[movement_index]) {
            '>' => .{ .x = 1, .y = 0 },
            '^' => .{ .x = 0, .y = -1 },
            '<' => .{ .x = -1, .y = 0 },
            'v' => .{ .x = 0, .y = 1 },
            else => unreachable,
        };
        if (grid.moveCheck(robot_pos, dir)) {
            _ = grid.move(robot_pos, dir);
            robot_pos = robot_pos.add(dir);
        }
    }
    var sum: i32 = 0;
    for (map_single_line, 0..) |item, i| {
        if (item == 'O') {
            const item_pos = grid.indexToPos(i);
            const gps_pos = item_pos.x + item_pos.y * 100;
            sum += gps_pos;
        }
    }
    {
        var print_pos: Vec2 = .{ .x = 0, .y = 0 };
        while (print_pos.y < grid.height) {
            print_pos.x = 0;
            while (print_pos.x < grid.width) {
                std.debug.print("{c}", .{grid.get(print_pos).?});
                print_pos.x += 1;
            }
            print_pos.y += 1;
            std.debug.print("\n", .{});
        }
    }
    return sum;
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(10092, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(1463512, result);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !i32 {
    var map_and_movements_strings = std.mem.tokenizeSequence(u8, input, "\n\n");
    const map_string = map_and_movements_strings.next().?;
    const movements_string = map_and_movements_strings.next().?;
    const map_single_line = try allocator.alloc(u8, 2 * std.mem.replacementSize(u8, map_string, "\n", ""));
    defer allocator.free(map_single_line);
    var index: usize = 0;
    var height: usize = 1;
    for (map_string) |char| {
        switch (char) {
            '#' => {
                map_single_line[index] = '#';
                map_single_line[index + 1] = '#';
                index += 2;
            },
            'O' => {
                map_single_line[index] = '[';
                map_single_line[index + 1] = ']';
                index += 2;
            },
            '.' => {
                map_single_line[index] = '.';
                map_single_line[index + 1] = '.';
                index += 2;
            },
            '@' => {
                map_single_line[index] = '@';
                map_single_line[index + 1] = '.';
                index += 2;
            },
            '\n' => {
                height += 1;
            },
            else => continue,
        }
    }
    const width = map_single_line.len / height;
    var grid: Grid = .{ .slice = map_single_line, .width = width, .height = height };
    const movements_single_line = try allocator.alloc(u8, std.mem.replacementSize(u8, movements_string, "\n", ""));
    defer allocator.free(movements_single_line);
    _ = std.mem.replace(u8, movements_string, "\n", "", movements_single_line);
    var robot_pos = grid.indexToPos(std.mem.indexOf(u8, map_single_line, "@").?);
    var movement_index: usize = 0;
    while (movement_index < movements_single_line.len) : (movement_index += 1) {
        const dir: Vec2 = switch (movements_single_line[movement_index]) {
            '>' => .{ .x = 1, .y = 0 },
            '^' => .{ .x = 0, .y = -1 },
            '<' => .{ .x = -1, .y = 0 },
            'v' => .{ .x = 0, .y = 1 },
            else => unreachable,
        };
        if (grid.moveCheck(robot_pos, dir)) {
            _ = grid.move(robot_pos, dir);
            robot_pos = robot_pos.add(dir);
        }
    }
    var sum: i32 = 0;
    for (map_single_line, 0..) |item, i| {
        if (item == '[') {
            const item_pos = grid.indexToPos(i);
            const gps_pos = item_pos.x + item_pos.y * 100;
            sum += gps_pos;
        }
    }
    return sum;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(9021, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(1486520, result);
}
