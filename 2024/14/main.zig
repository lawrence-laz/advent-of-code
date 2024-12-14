const std = @import("std");

// https://adventofcode.com/2024/day/14

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

fn solvePart1(input: []const u8, width: i32, height: i32) !usize {
    var robots_strings = std.mem.tokenizeScalar(u8, input, '\n');
    var quadrant_1: usize = 0;
    var quadrant_2: usize = 0;
    var quadrant_3: usize = 0;
    var quadrant_4: usize = 0;
    while (robots_strings.next()) |robot_string| {
        var pos_and_vel_string = std.mem.tokenizeScalar(u8, robot_string, ' ');
        var pos_strings = std.mem.tokenizeScalar(
            u8,
            pos_and_vel_string.next().?[2..], // Skip "p="
            ',',
        );
        var vel_strings = std.mem.tokenizeScalar(
            u8,
            pos_and_vel_string.next().?[2..], // Skip "v="
            ',',
        );
        const starting_pos: Vec2 = .{
            .x = try std.fmt.parseInt(i32, pos_strings.next().?, 10),
            .y = try std.fmt.parseInt(i32, pos_strings.next().?, 10),
        };
        const vel: Vec2 = .{
            .x = try std.fmt.parseInt(i32, vel_strings.next().?, 10),
            .y = try std.fmt.parseInt(i32, vel_strings.next().?, 10),
        };
        const end_pos_unbound = starting_pos.add(vel.mul(100));
        const end_pos_x_mod = @mod(end_pos_unbound.x, width);
        const end_pos_y_mod = @mod(end_pos_unbound.y, height);
        const end_pos: Vec2 = .{
            .x = if (std.math.sign(end_pos_x_mod) < 0) width + end_pos_x_mod else end_pos_x_mod,
            .y = if (std.math.sign(end_pos_y_mod) < 0) width + end_pos_y_mod else end_pos_y_mod,
        };

        const west = end_pos.x < @divTrunc(width, 2);
        const east = end_pos.x > @divTrunc(width, 2);
        const north = end_pos.y < @divTrunc(height, 2);
        const south = end_pos.y > @divTrunc(height, 2);
        if (north and west)
            quadrant_1 += 1
        else if (north and east)
            quadrant_2 += 1
        else if (south and west)
            quadrant_3 += 1
        else if (south and east)
            quadrant_4 += 1;
    }
    return quadrant_1 * quadrant_2 * quadrant_3 * quadrant_4;
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(input, 11, 7);
    try std.testing.expectEqual(12, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(input, 101, 103);
    try std.testing.expectEqual(228690000, result);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8, comptime width: i32, comptime height: i32, comptime start: i32) !i32 {
    var quadrant_1: usize = 1;
    var quadrant_2: usize = 2;
    var quadrant_3: usize = 3;
    var quadrant_4: usize = 4;
    var seconds: i32 = start;
    var positions: std.AutoHashMapUnmanaged(Vec2, void) = .{};
    defer positions.deinit(allocator);
    while (seconds < 9813) : (seconds += 1) {
        var robots_strings = std.mem.tokenizeScalar(u8, input, '\n');
        positions.clearRetainingCapacity();
        quadrant_1 = 0;
        quadrant_2 = 0;
        quadrant_3 = 0;
        quadrant_4 = 0;
        while (robots_strings.next()) |robot_string| {
            var pos_and_vel_string = std.mem.tokenizeScalar(u8, robot_string, ' ');
            var pos_strings = std.mem.tokenizeScalar(
                u8,
                pos_and_vel_string.next().?[2..], // Skip "p="
                ',',
            );
            var vel_strings = std.mem.tokenizeScalar(
                u8,
                pos_and_vel_string.next().?[2..], // Skip "v="
                ',',
            );
            const starting_pos: Vec2 = .{
                .x = try std.fmt.parseInt(i32, pos_strings.next().?, 10),
                .y = try std.fmt.parseInt(i32, pos_strings.next().?, 10),
            };
            const vel: Vec2 = .{
                .x = try std.fmt.parseInt(i32, vel_strings.next().?, 10),
                .y = try std.fmt.parseInt(i32, vel_strings.next().?, 10),
            };
            const end_pos_unbound = starting_pos.add(vel.mul(seconds));
            const end_pos_x_mod = @mod(end_pos_unbound.x, width);
            const end_pos_y_mod = @mod(end_pos_unbound.y, height);
            const end_pos: Vec2 = .{
                .x = if (std.math.sign(end_pos_x_mod) < 0) width + end_pos_x_mod else end_pos_x_mod,
                .y = if (std.math.sign(end_pos_y_mod) < 0) width + end_pos_y_mod else end_pos_y_mod,
            };
            try positions.put(allocator, end_pos, {});

            const west = end_pos.x < @divTrunc(width, 2);
            const east = end_pos.x > @divTrunc(width, 2);
            const north = end_pos.y < @divTrunc(height, 2);
            const south = end_pos.y > @divTrunc(height, 2);
            if (north and west)
                quadrant_1 += 1
            else if (north and east)
                quadrant_2 += 1
            else if (south and west)
                quadrant_3 += 1
            else if (south and east)
                quadrant_4 += 1;
        }
        var x: i32 = 0;
        var y: i32 = 0;
        while (y < height) : (y += 1) {
            x = 0;
            while (x < width) : (x += 1) {
                std.debug.print("{s}", .{if (positions.contains(.{ .x = x, .y = y })) "@" else " "});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("SECONDS = {d}\n\n\n", .{seconds});
        std.time.sleep(std.time.ns_per_ms * 2000);
    }
    return seconds;
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    _ = try solvePart2(std.testing.allocator, input, 101, 103, 7093);
}
