const std = @import("std");

// https://adventofcode.com/2024/day/23

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var graph: std.AutoArrayHashMapUnmanaged([2]u8, std.ArrayListUnmanaged([2]u8)) = .{};
    defer {
        for (graph.values()) |*value| value.deinit(allocator);
        graph.deinit(allocator);
    }

    var found: std.AutoHashMapUnmanaged([6]u8, void) = .{};
    defer found.deinit(allocator);

    var connections = std.mem.tokenizeScalar(u8, input, '\n');
    while (connections.next()) |connection| {
        const computer1: [2]u8 = connection[0..2].*;
        const computer2: [2]u8 = connection[3..5].*;

        const computer1_connections_result = try graph.getOrPutValue(allocator, computer1, .{});
        const computer1_connections = computer1_connections_result.value_ptr;
        try computer1_connections.append(allocator, computer2);

        const computer2_connections_result = try graph.getOrPutValue(allocator, computer2, .{});
        const computer2_connections = computer2_connections_result.value_ptr;
        try computer2_connections.append(allocator, computer1);
    }

    for (graph.keys()) |node| {
        if (node[0] != 't') continue;
        var visited: [3][2]u8 = undefined;
        try findParty(allocator, node, node, 0, &visited, &graph, &found);
    }

    return found.count();
}

fn findParty(
    allocator: std.mem.Allocator,
    starting_node: [2]u8,
    current_node: [2]u8,
    depth: usize,
    visited: *[3][2]u8,
    graph: *std.AutoArrayHashMapUnmanaged([2]u8, std.ArrayListUnmanaged([2]u8)),
    found: *std.AutoHashMapUnmanaged([6]u8, void),
) !void {
    if (depth == 3) {
        if (std.mem.eql(u8, &current_node, &starting_node)) {
            var ordered_nodes: [3][2]u8 = .{ visited[0], visited[1], visited[2] };
            std.mem.sort(
                [2]u8,
                &ordered_nodes,
                {},
                struct {
                    pub fn inner(_: void, a: [2]u8, b: [2]u8) bool {
                        return if (a[0] != b[0]) a[0] < b[0] else a[1] < b[1];
                    }
                }.inner,
            );
            try found.put(allocator, ordered_nodes[0] ++ ordered_nodes[1] ++ ordered_nodes[2], {});
        }
        return;
    }

    visited[depth] = current_node;
    const neighbours = graph.get(current_node);
    for (neighbours.?.items) |neighbour| {
        try findParty(allocator, starting_node, neighbour, depth + 1, visited, graph, found);
    }
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(7, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(1304, result);
}

fn solvePart2(input: []const u8) !u32 {
    _ = input;
    return 123;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(input);
    try std.testing.expectEqual(123, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(input);
    try std.testing.expectEqual(123, result);
}
