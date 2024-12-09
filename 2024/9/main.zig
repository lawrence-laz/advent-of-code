const std = @import("std");

// https://adventofcode.com/2024/day/9

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var disk: std.ArrayListUnmanaged(?usize) = .{};
    defer disk.deinit(allocator);
    for (input, 0..) |digit_char, i| {
        if (!std.ascii.isDigit(digit_char)) continue;
        const digit: usize = digit_char - '0';
        try disk.appendNTimes(allocator, if (i % 2 == 0) @divFloor(i, 2) else null, digit);
    }

    var free_index: usize = std.mem.indexOfScalar(?usize, disk.items, null).?;
    var tail_index: usize = std.mem.lastIndexOfNone(?usize, disk.items, &.{null}).?;
    while (free_index < tail_index) {
        std.mem.swap(?usize, &disk.items[free_index], &disk.items[tail_index]);
        free_index = std.mem.indexOfScalarPos(?usize, disk.items, free_index, null) orelse break;
        tail_index = std.mem.lastIndexOfNone(?usize, disk.items, &.{null}) orelse break;
    }

    var sum: usize = 0;
    for (disk.items[0..free_index], 0..) |digit, i| {
        sum += digit.? * i;
    }

    return sum;
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(1928, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(6307275788409, result);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var disk: std.ArrayListUnmanaged(?usize) = .{};
    defer disk.deinit(allocator);
    for (input, 0..) |digit_char, i| {
        if (!std.ascii.isDigit(digit_char)) continue;
        const digit: usize = digit_char - '0';
        try disk.appendNTimes(allocator, if (i % 2 == 0) @divFloor(i, 2) else null, digit);
    }

    var tail_end: usize = disk.items.len;
    const null_buff: [1000]?usize = .{null} ** 1000;
    while (tail_end > 0) {
        tail_end = std.mem.lastIndexOfNone(?usize, disk.items[0..tail_end], &.{null}) orelse break;
        const tail_start = std.mem.lastIndexOfNone(?usize, disk.items[0..tail_end], &.{disk.items[tail_end]}) orelse break;
        var memory_span = disk.items[tail_start + 1 .. tail_end + 1];
        tail_end = tail_start + 1;
        const free_span_start = std.mem.indexOf(?usize, disk.items[0..tail_end], (&null_buff)[0..memory_span.len]) orelse continue;
        const free_span = disk.items[free_span_start .. free_span_start + memory_span.len];
        var swap_index: usize = 0;
        while (swap_index < memory_span.len) : (swap_index += 1) {
            std.mem.swap(?usize, &memory_span[swap_index], &free_span[swap_index]);
        }
    }

    var sum: usize = 0;
    for (disk.items, 0..) |maybe_value, i| {
        if (maybe_value) |value| sum += value * i;
    }

    return sum;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(2858, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(6327174563252, result);
}
