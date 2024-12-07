const std = @import("std");

// https://adventofcode.com/2024/day/7
fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const multiplication: u1 = 0;
    const addition: u1 = 1;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var numbers: std.ArrayListUnmanaged(u64) = .{};
    defer numbers.deinit(allocator);
    var operations: u64 = 0;
    var total_sum: u64 = 0;

    while (lines.next()) |line| {
        numbers.clearRetainingCapacity();

        var parts = std.mem.tokenizeSequence(u8, line, ": ");
        const expected_answer = try std.fmt.parseInt(u64, parts.next().?, 10);
        var numbers_text = std.mem.tokenizeScalar(u8, parts.next().?, ' ');
        while (numbers_text.next()) |number_text| try numbers.append(allocator, try std.fmt.parseInt(u64, number_text, 10));

        var permutation: usize = 0;
        const operations_count: usize = numbers.items.len - 1;

        while (permutation < std.math.pow(usize, 2, operations_count)) : (permutation += 1) {
            var operation_index: usize = 0;
            var actual_answer: u64 = numbers.items[0];
            while (operation_index < operations_count) : (operation_index += 1) {
                const number_index = operation_index + 1;
                switch (getBit(operations, operation_index)) {
                    multiplication => actual_answer *= numbers.items[number_index],
                    addition => actual_answer += numbers.items[number_index],
                }
            }

            if (actual_answer == expected_answer) {
                total_sum += actual_answer;
                break;
            }

            operations += 1;
        }
    }

    return total_sum;
}

fn getBit(number: anytype, bit_index: usize) u1 {
    return @intCast((number & (@as(@TypeOf(number), 1) <<| bit_index)) >> @intCast(bit_index));
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(3749, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(6231007345478, result);
}

fn PermutationsIter(comptime T: type, base: usize) type {
    return struct {
        length: usize,
        index: usize,

        pub fn init(length: usize) @This() {
            return .{ .length = length, .index = 0 };
        }

        pub fn next(self: *@This(), buf: []T) ?[]T {
            if (self.index < std.math.pow(usize, base, self.length)) {
                buf[0] += 1;
                var carry: T = buf[0] / base;
                buf[0] %= base;
                var index: usize = 1;
                while (carry > 0 and index < buf.len) : (index += 1) {
                    buf[index] += carry;
                    carry = buf[index] / base;
                    buf[index] %= base;
                }
                self.index += 1;
                return buf;
            } else return null;
        }
    };
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const multiplication: u2 = 0;
    const addition: u2 = 1;
    const concat: u2 = 2;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var numbers: std.ArrayListUnmanaged(u64) = .{};
    defer numbers.deinit(allocator);
    var operations_buf: std.ArrayListUnmanaged(u64) = .{};
    defer operations_buf.deinit(allocator);
    var total_sum: u64 = 0;
    var concat_buf: [1000]u8 = undefined;

    while (lines.next()) |line| {
        numbers.clearRetainingCapacity();
        operations_buf.clearRetainingCapacity();

        var parts = std.mem.tokenizeSequence(u8, line, ": ");
        const expected_answer = try std.fmt.parseInt(u64, parts.next().?, 10);
        var numbers_text = std.mem.tokenizeScalar(u8, parts.next().?, ' ');
        while (numbers_text.next()) |number_text| try numbers.append(allocator, try std.fmt.parseInt(u64, number_text, 10));

        const operations_count: usize = numbers.items.len - 1;
        try operations_buf.appendNTimes(allocator, 0, operations_count);

        var permutations = PermutationsIter(u64, 3).init(operations_count);
        while (permutations.next(operations_buf.items)) |operations| {
            var operation_index: usize = 0;
            var actual_answer: u64 = numbers.items[0];
            while (operation_index < operations_count) : (operation_index += 1) {
                const number_index = operation_index + 1;
                switch (operations[operation_index]) {
                    multiplication => actual_answer *= numbers.items[number_index],
                    addition => actual_answer += numbers.items[number_index],
                    concat => {
                        // This could be binary concatenation, but eh
                        const concatenated = try std.fmt.bufPrint(&concat_buf, "{d}{d}", .{ actual_answer, numbers.items[number_index] });
                        actual_answer = try std.fmt.parseInt(u64, concatenated, 10);
                    },
                    else => unreachable,
                }
            }

            if (actual_answer == expected_answer) {
                total_sum += actual_answer;
                break;
            }
        }
    }

    return total_sum;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(11387, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(333027885676693, result);
}
