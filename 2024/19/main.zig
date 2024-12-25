const std = @import("std");

// https://adventofcode.com/2024/day/19

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var items_and_patterns_iter = std.mem.tokenizeSequence(u8, input, "\n\n");

    var max_seek_length: usize = 0;
    var items_iter = std.mem.tokenizeSequence(u8, items_and_patterns_iter.next().?, ", ");
    var items: std.StringHashMapUnmanaged(void) = .{};
    defer items.deinit(allocator);
    while (items_iter.next()) |item| {
        try items.put(allocator, item, {});
        if (max_seek_length < item.len) max_seek_length = item.len;
    }

    var patterns_iter = std.mem.tokenizeScalar(u8, items_and_patterns_iter.next().?, '\n');
    var possible_pattern_count: usize = 0;
    var from: std.ArrayListUnmanaged(usize) = .{};
    defer from.deinit(allocator);
    var seek_length: std.ArrayListUnmanaged(usize) = .{};
    defer seek_length.deinit(allocator);
    var impossible_patterns: std.StringHashMapUnmanaged(void) = .{};
    defer impossible_patterns.deinit(allocator);
    var possible_patterns: std.StringHashMapUnmanaged(usize) = .{};
    defer possible_patterns.deinit(allocator);

    next_pattern: while (patterns_iter.next()) |pattern| {
        std.debug.print("START: {s}\n", .{pattern});
        from.clearRetainingCapacity();
        seek_length.clearRetainingCapacity();

        try from.append(allocator, 0);
        try seek_length.append(allocator, 1);

        check_pattern: while (from.items.len > 0) {
            if (from.getLast() == pattern.len) {
                possible_pattern_count += 1;
                std.debug.print("SUCCESS: {s}\n", .{pattern});
                continue :next_pattern;
            }

            const seek_pattern = pattern[from.getLast() .. from.getLast() + seek_length.getLast()];
            std.debug.print("seek from {d} take {d}: {s}\n", .{ from.getLast(), seek_length.getLast(), seek_pattern });

            if (items.contains(seek_pattern)) {
                try from.append(allocator, from.getLast() + seek_pattern.len);
                try seek_length.append(allocator, 1);
                std.debug.print("found: {s}\n", .{pattern[0..from.getLast()]});
                continue :check_pattern;
            }

            while (seek_length.getLast() + 1 > pattern[from.getLast()..].len or
                seek_length.getLast() + 1 > max_seek_length or
                impossible_patterns.contains(pattern[from.getLast()..]))
            {
                try impossible_patterns.put(allocator, pattern[from.getLast()..], {});
                std.debug.print("pop\n", .{});
                _ = from.pop();
                _ = seek_length.pop();
                if (from.items.len == 0) {
                    continue :next_pattern;
                }
            }

            seek_length.items[seek_length.items.len - 1] += 1;
            continue :check_pattern;
        }
    }

    return possible_pattern_count;
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(6, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(206, result);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var items_and_patterns_iter = std.mem.tokenizeSequence(u8, input, "\n\n");

    var max_seek_length: usize = 0;
    var items_iter = std.mem.tokenizeSequence(u8, items_and_patterns_iter.next().?, ", ");
    var items: std.StringHashMapUnmanaged(void) = .{};
    defer items.deinit(allocator);
    while (items_iter.next()) |item| {
        try items.put(allocator, item, {});
        if (max_seek_length < item.len) max_seek_length = item.len;
    }

    var patterns_iter = std.mem.tokenizeScalar(u8, items_and_patterns_iter.next().?, '\n');
    var possible_pattern_count: usize = 0;
    var from: std.ArrayListUnmanaged(usize) = .{};
    defer from.deinit(allocator);
    var seek_length: std.ArrayListUnmanaged(usize) = .{};
    defer seek_length.deinit(allocator);
    var impossible_patterns: std.StringHashMapUnmanaged(void) = .{};
    defer impossible_patterns.deinit(allocator);
    var possible_patterns: std.StringHashMapUnmanaged(usize) = .{};
    defer possible_patterns.deinit(allocator);

    next_pattern: while (patterns_iter.next()) |pattern| {
        std.debug.print("START: {s}\n", .{pattern});
        from.clearRetainingCapacity();
        seek_length.clearRetainingCapacity();

        try from.append(allocator, 0);
        try seek_length.append(allocator, 1);

        check_pattern: while (from.items.len > 0) {
            if (from.getLast() == pattern.len) {
                possible_pattern_count += 1;
                std.debug.print("SUCCESS: {s}\n", .{pattern});
                _ = from.pop();
                _ = seek_length.pop();
                if (from.items.len == 0) {
                    continue :next_pattern;
                }
            } else {
                const seek_pattern = pattern[from.getLast() .. from.getLast() + seek_length.getLast()];
                std.debug.print("seek from {d} take {d}: {s}\n", .{ from.getLast(), seek_length.getLast(), seek_pattern });

                if (items.contains(seek_pattern)) {
                    try from.append(allocator, from.getLast() + seek_pattern.len);
                    try seek_length.append(allocator, 1);
                    std.debug.print("found: {s}\n", .{pattern[0..from.getLast()]});
                    continue :check_pattern;
                }
            }

            while (seek_length.getLast() + 1 > pattern[from.getLast()..].len or
                seek_length.getLast() + 1 > max_seek_length or
                impossible_patterns.contains(pattern[from.getLast()..]))
            {
                try impossible_patterns.put(allocator, pattern[from.getLast()..], {});
                std.debug.print("pop\n", .{});
                _ = from.pop();
                _ = seek_length.pop();
                if (from.items.len == 0) {
                    continue :next_pattern;
                }
            }

            seek_length.items[seek_length.items.len - 1] += 1;
            continue :check_pattern;
        }
    }

    return possible_pattern_count;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(16, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(123, result);
}
