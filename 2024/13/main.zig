const std = @import("std");

// https://adventofcode.com/2024/day/13

const Vec2 = struct {
    x: i128,
    y: i128,

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

fn solvePart1(input: []const u8) !i128 {
    var machines_input = std.mem.tokenizeSequence(u8, input, "\n\n");
    var total_tokens: i128 = 0;
    while (machines_input.next()) |machine_input| {
        var maybe_cheapest: ?i128 = null;
        var parts = std.mem.tokenizeScalar(u8, machine_input, '\n');
        const button_a = if (parts.next()) |string| Vec2{
            .x = try std.fmt.parseInt(i32, string[12..14], 10),
            .y = try std.fmt.parseInt(i32, string[18..20], 10),
        } else unreachable;
        const button_b = if (parts.next()) |string| Vec2{
            .x = try std.fmt.parseInt(i32, string[12..14], 10),
            .y = try std.fmt.parseInt(i32, string[18..20], 10),
        } else unreachable;
        const prize = blk: {
            if (parts.next()) |string| {
                var coords_string = std.mem.tokenizeSequence(u8, string[7..], ", ");
                break :blk Vec2{
                    .x = try std.fmt.parseInt(i32, coords_string.next().?[2..], 10),
                    .y = try std.fmt.parseInt(i32, coords_string.next().?[2..], 10),
                };
            } else unreachable;
        };
        var a_count: i128 = 0;
        var b_count: i128 = 0;
        while (a_count <= 100) : (a_count += 1) {
            b_count = 0;
            while (b_count <= 100) : (b_count += 1) {
                if (prize.x == button_a.x * a_count + button_b.x * b_count and
                    prize.y == button_a.y * a_count + button_b.y * b_count)
                {
                    const price = a_count * 3 + b_count;
                    if (maybe_cheapest) |cheapest| {
                        if (price < cheapest) maybe_cheapest = price;
                    } else {
                        maybe_cheapest = price;
                    }
                }
            }
        }
        if (maybe_cheapest) |cheapest| {
            total_tokens += cheapest;
        }
    }

    return total_tokens;
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(input);
    try std.testing.expectEqual(480, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(input);
    try std.testing.expectEqual(26005, result);
}

// Today I learned: https://en.wikipedia.org/wiki/Cramer%27s_rule
fn cramer(a: Vec2, b: Vec2, c: Vec2) !Vec2 {
    return .{
        .x = try std.math.divExact(i128, (c.x * b.y - b.x * c.y), (a.x * b.y - b.x * a.y)),
        .y = try std.math.divExact(i128, (a.x * c.y - c.x * a.y), (a.x * b.y - b.x * a.y)),
    };
}

fn solvePart2(input: []const u8) !i128 {
    var machines_input = std.mem.tokenizeSequence(u8, input, "\n\n");
    var total_tokens: i128 = 0;
    while (machines_input.next()) |machine_input| {
        var buttons_and_prize = std.mem.tokenizeScalar(u8, machine_input, '\n');
        const button_a = if (buttons_and_prize.next()) |string| Vec2{
            .x = try std.fmt.parseInt(i32, string[12..14], 10),
            .y = try std.fmt.parseInt(i32, string[18..20], 10),
        } else unreachable;
        const button_b = if (buttons_and_prize.next()) |string| Vec2{
            .x = try std.fmt.parseInt(i32, string[12..14], 10),
            .y = try std.fmt.parseInt(i32, string[18..20], 10),
        } else unreachable;
        const prize_before = blk: {
            if (buttons_and_prize.next()) |string| {
                var coords_string = std.mem.tokenizeSequence(u8, string[7..], ", "); // Skip "Prize: "
                break :blk Vec2{
                    .x = try std.fmt.parseInt(i32, coords_string.next().?[2..], 10), // Skip "X="
                    .y = try std.fmt.parseInt(i32, coords_string.next().?[2..], 10), // Skip "Y="
                };
            } else unreachable;
        };
        const prize: Vec2 = .{
            .x = prize_before.x + 10000000000000,
            .y = prize_before.y + 10000000000000,
        };
        const count = cramer(button_a, button_b, prize) catch continue;
        total_tokens += count.x * 3 + count.y;
    }
    return total_tokens;
}

test "example input part2" {
    const input =
        \\Button A: X+26, Y+66
        \\Button B: X+67, Y+21
        \\Prize: X=12748, Y=12176
    ;
    const result = try solvePart2(input);
    try std.testing.expectEqual(459236326669, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(input);
    try std.testing.expectEqual(105620095782547, result);
}
