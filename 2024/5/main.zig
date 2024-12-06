const std = @import("std");

// https://adventofcode.com/2024/day/5
fn solvePart1(allocator: std.mem.Allocator, input_text: []const u8) !u32 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var parts = std.mem.splitSequence(u8, input_text, "\n\n");
    const ordering_rules_text = parts.next().?;
    const pages_input_text = parts.next().?;

    var ordering_rules_lines = std.mem.splitScalar(u8, ordering_rules_text, '\n');
    var ordering_rules = std.AutoHashMap(u8, std.ArrayList(u8)).init(arena.allocator());
    while (ordering_rules_lines.next()) |ordering_rule_line| {
        var ordering_rule_parts = std.mem.splitScalar(u8, ordering_rule_line, '|');
        const before = try std.fmt.parseInt(u8, ordering_rule_parts.next().?, 10);
        const after = try std.fmt.parseInt(u8, ordering_rule_parts.next().?, 10);
        var after_items = ordering_rules.getPtr(before) orelse blk: {
            try ordering_rules.put(before, std.ArrayList(u8).init(arena.allocator()));
            break :blk ordering_rules.getPtr(before).?;
        };
        try after_items.append(after);
    }

    var pages_buf = std.ArrayList(u8).init(arena.allocator());
    var prev_pages = std.AutoHashMap(u8, void).init(arena.allocator());
    var pages_lines = std.mem.splitScalar(u8, pages_input_text, '\n');
    var result: u32 = 0;
    while (pages_lines.next()) |page_line| {
        pages_buf.clearRetainingCapacity();
        prev_pages.clearRetainingCapacity();
        var pages = std.mem.tokenizeScalar(u8, page_line, ',');
        while (pages.next()) |page| {
            try pages_buf.append(try std.fmt.parseInt(u8, page, 10));
        }

        if (pages_buf.items.len == 0) continue;

        const is_right_order: bool = blk: {
            for (pages_buf.items) |page| {
                if (ordering_rules.get(page)) |ordering_rule|
                    for (ordering_rule.items) |page_after|
                        if (prev_pages.contains(page_after)) break :blk false;
                try prev_pages.put(page, {});
            }
            break :blk true;
        };
        if (is_right_order) {
            const middle_page = pages_buf.items[pages_buf.items.len / 2];
            result += middle_page;
        }
    }

    return result;
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(143, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(5713, result);
}

fn lessThanFn(context: std.AutoHashMap(u8, std.ArrayList(u8)), lhs: u8, rhs: u8) bool {
    if (context.get(lhs)) |lhs_rule| return std.mem.containsAtLeast(u8, lhs_rule.items, 1, &.{rhs});
    if (context.get(rhs)) |rhs_rule| return !std.mem.containsAtLeast(u8, rhs_rule.items, 1, &.{lhs});
    return true;
}

fn solvePart2(allocator: std.mem.Allocator, input_text: []const u8) !u32 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var parts = std.mem.splitSequence(u8, input_text, "\n\n");
    const ordering_rules_text = parts.next().?;
    const pages_input_text = parts.next().?;

    var ordering_rules_lines = std.mem.splitScalar(u8, ordering_rules_text, '\n');
    var ordering_rules = std.AutoHashMap(u8, std.ArrayList(u8)).init(arena.allocator());
    while (ordering_rules_lines.next()) |ordering_rule_line| {
        var ordering_rule_parts = std.mem.splitScalar(u8, ordering_rule_line, '|');
        const before = try std.fmt.parseInt(u8, ordering_rule_parts.next().?, 10);
        const after = try std.fmt.parseInt(u8, ordering_rule_parts.next().?, 10);
        var after_items = ordering_rules.getPtr(before) orelse blk: {
            try ordering_rules.put(before, std.ArrayList(u8).init(arena.allocator()));
            break :blk ordering_rules.getPtr(before).?;
        };
        try after_items.append(after);
    }

    var pages_buf = std.ArrayList(u8).init(arena.allocator());
    var prev_pages = std.AutoHashMap(u8, void).init(arena.allocator());
    var pages_lines = std.mem.splitScalar(u8, pages_input_text, '\n');
    var result: u32 = 0;
    while (pages_lines.next()) |page_line| {
        pages_buf.clearRetainingCapacity();
        prev_pages.clearRetainingCapacity();
        var pages = std.mem.tokenizeScalar(u8, page_line, ',');
        while (pages.next()) |page| {
            try pages_buf.append(try std.fmt.parseInt(u8, page, 10));
        }

        if (pages_buf.items.len == 0) continue;

        if (!std.sort.isSorted(u8, pages_buf.items, ordering_rules, lessThanFn)) {
            std.sort.pdq(u8, pages_buf.items, ordering_rules, lessThanFn);
            const middle_page = pages_buf.items[pages_buf.items.len / 2];
            result += middle_page;
        }
    }

    return result;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(123, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(5180, result);
}
