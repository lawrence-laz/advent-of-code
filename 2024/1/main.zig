const std = @import("std");

// https://adventofcode.com/2024/day/1
fn solvePart1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var left_list = std.ArrayListUnmanaged(i32){};
    defer left_list.deinit(allocator);

    var right_list = std.ArrayListUnmanaged(i32){};
    defer right_list.deinit(allocator);

    while (lines.next()) |line| {
        var pair = std.mem.tokenizeScalar(u8, line, ' ');

        const left_item = pair.next().?;
        const left_id = try std.fmt.parseInt(i32, left_item, 10);
        try left_list.append(allocator, left_id);

        const right_item = pair.next().?;
        const right_id = try std.fmt.parseInt(i32, right_item, 10);
        try right_list.append(allocator, right_id);
    }

    std.mem.sort(i32, left_list.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, right_list.items, {}, std.sort.asc(i32));

    var total_distance: u32 = 0;
    for (left_list.items, right_list.items) |left_item, right_item| {
        total_distance += @abs(left_item - right_item);
    }

    return total_distance;
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(input, std.testing.allocator);
    try std.testing.expectEqual(11, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(input, std.testing.allocator);
    try std.testing.expectEqual(2066446, result);
}

fn solvePart2(input: []const u8, allocator: std.mem.Allocator) !usize {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var left_list = std.ArrayListUnmanaged(i32){};
    defer left_list.deinit(allocator);

    var right_list = std.ArrayListUnmanaged(i32){};
    defer right_list.deinit(allocator);

    while (lines.next()) |line| {
        var pair = std.mem.tokenizeScalar(u8, line, ' ');

        const left_item = pair.next().?;
        const left_id = try std.fmt.parseInt(i32, left_item, 10);
        try left_list.append(allocator, left_id);

        const right_item = pair.next().?;
        const right_id = try std.fmt.parseInt(i32, right_item, 10);
        try right_list.append(allocator, right_id);
    }

    std.mem.sort(i32, left_list.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, right_list.items, {}, std.sort.asc(i32));

    var similarity_score: usize = 0;
    for (left_list.items) |left_item| {
        const appearance_count = std.mem.count(i32, right_list.items, &.{left_item});
        similarity_score += @as(usize, @intCast(left_item)) * appearance_count;
    }

    return similarity_score;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(input, std.testing.allocator);
    try std.testing.expectEqual(31, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(input, std.testing.allocator);
    try std.testing.expectEqual(24931009, result);
}
