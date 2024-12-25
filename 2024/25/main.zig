const std = @import("std");

// https://adventofcode.com/2024/day/25

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var keys: std.ArrayListUnmanaged([5]u8) = .{};
    defer keys.deinit(allocator);
    var locks: std.ArrayListUnmanaged([5]u8) = .{};
    defer locks.deinit(allocator);
    var keys_and_locks_iter = std.mem.tokenizeSequence(u8, input, "\n\n");
    while (keys_and_locks_iter.next()) |key_or_lock| {
        var heights: [5]u8 = .{0} ** 5;
        var lines = std.mem.tokenizeScalar(u8, key_or_lock, '\n');
        while (lines.next()) |line| {
            for (line, 0..) |char, i| {
                if (char == '#') {
                    heights[i] += 1;
                }
            }
        }
        for (heights, 0..) |_, i| {
            heights[i] -= 1;
        }

        if (key_or_lock[0] == '#') {
            try locks.append(allocator, heights);
        } else {
            try keys.append(allocator, heights);
        }
    }

    var fit_count: usize = 0;
    for (keys.items) |key| {
        for (locks.items) |lock| {
            var i: usize = 0;
            const fits = blk: {
                while (i < lock.len) : (i += 1) {
                    if (key[i] + lock[i] > 5) break :blk false;
                }
                break :blk true;
            };
            if (fits) {
                fit_count += 1;
            }
        }
    }

    return fit_count;
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(3, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(2840, result);
}
