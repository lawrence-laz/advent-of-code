const std = @import("std");

// https://adventofcode.com/2024/day/24

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !u46 {
    var initial_values_and_gate_connections = std.mem.tokenizeSequence(u8, input, "\n\n");

    var values: std.AutoHashMapUnmanaged([3]u8, bool) = .{};
    defer values.deinit(allocator);
    const initial_values_string = initial_values_and_gate_connections.next().?;
    var initial_values_iter = std.mem.tokenizeScalar(u8, initial_values_string, '\n');
    while (initial_values_iter.next()) |initial_value_string| {
        try values.put(
            allocator,
            initial_value_string[0..3].*,
            if (initial_value_string[5] == '1') true else false,
        );
    }

    var gate_connections: std.ArrayListUnmanaged(LogicGate) = .{};
    defer gate_connections.deinit(allocator);
    const gate_connections_string = initial_values_and_gate_connections.next().?;
    var gate_connections_iter = std.mem.tokenizeScalar(u8, gate_connections_string, '\n');
    while (gate_connections_iter.next()) |gate_connection_string| {
        var tokens = std.mem.tokenizeScalar(u8, gate_connection_string, ' ');
        const input1 = tokens.next().?;
        const operator: Operator = switch (tokens.next().?[0]) {
            'X' => .xor,
            'O' => .@"or",
            'A' => .@"and",
            else => unreachable,
        };
        const input2 = tokens.next().?;
        _ = tokens.next(); // Arrow
        const output = tokens.next().?;
        try gate_connections.append(allocator, .{
            .input1 = input1[0..3].*,
            .input2 = input2[0..3].*,
            .operator = operator,
            .output = output[0..3].*,
        });
    }

    while (gate_connections.items.len > 0) {
        var i: usize = 0;
        while (i < gate_connections.items.len) : (i += 1) {
            if (try gate_connections.items[i].tryProduceOutput(allocator, &values)) {
                _ = gate_connections.swapRemove(i);
            }
        }
    }

    var output: u46 = 0;
    var buf: [3]u8 = .{0} ** 3;
    var i: u6 = 0;
    while (values.get((try std.fmt.bufPrint(&buf, "z{d:0>2}", .{i}))[0..3].*)) |bit_value| {
        if (bit_value) output |= @as(u46, 1) << i;
        i += 1;
    }

    return output;
}

const Operator = enum { xor, @"or", @"and" };

const LogicGate = struct {
    input1: [3]u8,
    input2: [3]u8,
    operator: Operator,
    output: [3]u8,

    fn tryProduceOutput(
        self: *@This(),
        allocator: std.mem.Allocator,
        values: *std.AutoHashMapUnmanaged([3]u8, bool),
    ) !bool {
        if (values.get(self.input1)) |input1| if (values.get(self.input2)) |input2| {
            try values.put(allocator, self.output, switch (self.operator) {
                .xor => input1 != input2,
                .@"and" => input1 and input2,
                .@"or" => input1 or input2,
            });
            return true;
        };
        return false;
    }
};

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(2024, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(53190357879014, result);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !void {
    var initial_values_and_gate_connections = std.mem.tokenizeSequence(u8, input, "\n\n");

    var values: std.AutoHashMapUnmanaged([3]u8, bool) = .{};
    defer values.deinit(allocator);
    const initial_values_string = initial_values_and_gate_connections.next().?;
    var initial_values_iter = std.mem.tokenizeScalar(u8, initial_values_string, '\n');
    while (initial_values_iter.next()) |initial_value_string| {
        try values.put(
            allocator,
            initial_value_string[0..3].*,
            if (initial_value_string[5] == '1') true else false,
        );
    }

    var gate_connections: std.ArrayListUnmanaged(LogicGate) = .{};
    defer gate_connections.deinit(allocator);
    const gate_connections_string = initial_values_and_gate_connections.next().?;
    var gate_connections_iter = std.mem.tokenizeScalar(u8, gate_connections_string, '\n');
    while (gate_connections_iter.next()) |gate_connection_string| {
        var tokens = std.mem.tokenizeScalar(u8, gate_connection_string, ' ');
        const input1 = tokens.next().?;
        const operator: Operator = switch (tokens.next().?[0]) {
            'X' => .xor,
            'O' => .@"or",
            'A' => .@"and",
            else => unreachable,
        };
        const input2 = tokens.next().?;
        _ = tokens.next(); // Arrow
        const output = tokens.next().?;
        try gate_connections.append(allocator, .{
            .input1 = input1[0..3].*,
            .input2 = input2[0..3].*,
            .operator = operator,
            .output = output[0..3].*,
        });
    }

    while (gate_connections.items.len > 0) {
        var i: usize = 0;
        while (i < gate_connections.items.len) : (i += 1) {
            if (try gate_connections.items[i].tryProduceOutput(allocator, &values)) {
                _ = gate_connections.swapRemove(i);
            }
        }
    }

    var buf: [3]u8 = .{0} ** 3;

    var x: u46 = 0;
    var i: u6 = 0;
    while (values.get((try std.fmt.bufPrint(&buf, "x{d:0>2}", .{i}))[0..3].*)) |bit_value| {
        if (bit_value) x |= @as(u46, 1) << i;
        i += 1;
    }

    var y: u46 = 0;
    i = 0;
    while (values.get((try std.fmt.bufPrint(&buf, "y{d:0>2}", .{i}))[0..3].*)) |bit_value| {
        if (bit_value) y |= @as(u46, 1) << i;
        i += 1;
    }

    var z: u46 = 0;
    i = 0;
    while (values.get((try std.fmt.bufPrint(&buf, "z{d:0>2}", .{i}))[0..3].*)) |bit_value| {
        if (bit_value) z |= @as(u46, 1) << i;
        i += 1;
    }

    std.log.debug("{d} + {d} = {d} ({d})", .{ x, y, x + y, z });
    std.debug.print("\n{b:0>46}", .{x});
    std.debug.print("\n{b:0>46}", .{y});
    std.debug.print("\n{b}", .{x + y});
    std.debug.print("\n{b}\n", .{z});
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    try solvePart2(std.testing.allocator, input);
    // This is a funny one, solved by hand just by looking at which bits are off and running:
    // find . -name 'real-input.txt' | entr zig test --test-filter "real input part2" main.zig
    // Answer: bks,hnd,nrn,tdv,tjp,z09,z16,z23
}
