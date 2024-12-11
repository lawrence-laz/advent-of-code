const std = @import("std");

// https://adventofcode.com/2024/day/11

var cache: std.AutoHashMapUnmanaged(struct { usize, usize }, usize) = .{};

fn blink(allocator: std.mem.Allocator, stone: usize, repeat: usize) !usize {
    if (repeat == 0) return 1;

    if (cache.get(.{ stone, repeat })) |stone_count| return stone_count;

    if (stone == 0) return try blink(allocator, 1, repeat - 1);

    const digits: usize = getDigits(stone);
    if (digits % 2 == 0) {
        const digits_factor = std.math.pow(usize, 10, digits / 2);
        const left: usize = stone / digits_factor;
        const right: usize = stone % digits_factor;
        const count = try blink(allocator, left, repeat - 1) + try blink(allocator, right, repeat - 1);
        try cache.put(allocator, .{ stone, repeat }, count);
        return count;
    }

    return try blink(allocator, stone * 2024, repeat - 1);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, repeat: usize) !usize {
    var input_numbers = std.mem.tokenizeAny(u8, input, " \n");
    var total_count: usize = 0;
    while (input_numbers.next()) |number| {
        const stone = try std.fmt.parseInt(usize, number, 10);
        total_count += try blink(allocator, stone, repeat);
    }
    return total_count;
}

fn getDigits(number: usize) usize {
    var local = number;
    var digits: usize = 0;
    while (local >= 10) {
        local /= 10;
        digits += 1;
    }
    return digits + 1;
}

test "example input part1" {
    defer cache.deinit(std.testing.allocator);
    const input = @embedFile("./example-input.txt");
    const result = try solve(std.testing.allocator, input, 25);
    try std.testing.expectEqual(55312, result);
}

test "real input part1" {
    defer cache.deinit(std.testing.allocator);
    const input = @embedFile("./real-input.txt");
    const result = try solve(std.testing.allocator, input, 25);
    try std.testing.expectEqual(222461, result);
}

test "example input part2" {
    defer cache.deinit(std.testing.allocator);
    const input = @embedFile("./example-input.txt");
    const result = try solve(std.testing.allocator, input, 75);
    try std.testing.expectEqual(65601038650482, result);
}

test "real input part2" {
    defer cache.deinit(std.testing.allocator);
    const input = @embedFile("./real-input.txt");
    const result = try solve(std.testing.allocator, input, 75);
    try std.testing.expectEqual(264350935776416, result);
}
