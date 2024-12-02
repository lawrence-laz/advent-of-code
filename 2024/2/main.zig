const std = @import("std");

// https://adventofcode.com/2024/day/2
fn solvePart1(input: []const u8, allocator: std.mem.Allocator) !usize {
    var reports = std.mem.tokenizeScalar(u8, input, '\n');
    var levels = std.ArrayListUnmanaged(usize){};
    defer levels.deinit(allocator);
    var stable_count: usize = 0;
    while (reports.next()) |report| {
        defer levels.clearRetainingCapacity();
        var levels_iter = std.mem.tokenizeScalar(u8, report, ' ');
        while (levels_iter.next()) |level| try levels.append(allocator, try std.fmt.parseUnsigned(usize, level, 10));

        var level_pairs = std.mem.window(usize, levels.items, 2, 1);
        var prev_direction: Direction = .unknown;
        const is_stable: bool = blk: {
            while (level_pairs.next()) |pair| {
                const left = pair[0];
                const right = pair[1];

                const delta = if (left > right) left - right else right - left;
                if (delta < 1 or delta > 3) {
                    break :blk false;
                }

                const direction: Direction = if (left > right) .decreasing else if (left < right) .increasing else unreachable;
                if (prev_direction == .increasing and direction == .decreasing or
                    prev_direction == .decreasing and direction == .increasing)
                {
                    break :blk false;
                }

                prev_direction = direction;
            }
            break :blk true;
        };

        if (is_stable) stable_count += 1;
    }
    return stable_count;
}

const Direction = enum { unknown, increasing, decreasing };

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(input, std.testing.allocator);
    try std.testing.expectEqual(2, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(input, std.testing.allocator);
    try std.testing.expectEqual(591, result);
}

fn solvePart2(input: []const u8, allocator: std.mem.Allocator) !usize {
    var reports = std.mem.tokenizeScalar(u8, input, '\n');
    var levels = std.ArrayListUnmanaged(usize){};
    defer levels.deinit(allocator);

    var stable_count: usize = 0;
    while (reports.next()) |report| {
        defer levels.clearRetainingCapacity();
        var levels_iter = std.mem.tokenizeScalar(u8, report, ' ');
        while (levels_iter.next()) |level| try levels.append(allocator, try std.fmt.parseUnsigned(usize, level, 10));
        if (isStableWithTheProblemDampener(&levels)) stable_count += 1;
    }

    return stable_count;
}

fn isStableWithTheProblemDampener(levels: *std.ArrayListUnmanaged(usize)) bool {
    if (isStable(levels.items)) {
        return true;
    }

    // The Problem Dampener
    var remove_index: usize = 0;
    var removed_level: usize = 0;
    while (remove_index < levels.items.len) : (remove_index += 1) {
        removed_level = levels.orderedRemove(remove_index);

        if (isStable(levels.items)) {
            return true;
        }

        levels.insertAssumeCapacity(remove_index, removed_level);
    }

    return false;
}

fn isStable(levels: []usize) bool {
    var level_pairs = std.mem.window(usize, levels, 2, 1);
    var prev_direction: Direction = .unknown;
    return blk: {
        while (level_pairs.next()) |pair| {
            const left = pair[0];
            const right = pair[1];

            const delta = if (left > right) left - right else right - left;
            const bad_delta = delta < 1 or delta > 3;

            const direction: Direction = if (left > right) .decreasing else if (left < right) .increasing else .unknown;
            const bad_direction = prev_direction == .increasing and direction == .decreasing or
                prev_direction == .decreasing and direction == .increasing;

            if (bad_delta or bad_direction) break :blk false;
            if (prev_direction == .unknown) prev_direction = direction;
        }
        break :blk true;
    };
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(input, std.testing.allocator);
    try std.testing.expectEqual(4, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(input, std.testing.allocator);
    try std.testing.expectEqual(621, result);
}
