const std = @import("std");

// https://adventofcode.com/2023/day/1
fn solve(input: []const u8) !u32 {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var result: u32 = 0;
    while (lines.next()) |line| {
        var first_digit_index: ?usize = null;
        var last_digit_index: ?usize = null;
        for (line, 0..) |char, index| {
            var is_digit = switch (char) {
                '0'...'9' => true,
                else => false,
            };
            if (is_digit) {
                last_digit_index = index;
                if (first_digit_index == null) {
                    first_digit_index = index;
                }
            }
        }
        const first_digit = line[first_digit_index.?];
        const last_digit = line[last_digit_index.?];
        result = result + try std.fmt.parseUnsigned(u32, &[2]u8{ first_digit, last_digit }, 10);
    }
    return result;
}

test "example input" {
    const input = @embedFile("./example-input.txt");
    const result = try solve(input);
    const expected: u32 = 142;
    try std.testing.expectEqual(expected, result);
}

test "real input" {
    const input = @embedFile("./real-input.txt");
    const result = try solve(input);
    const expected: u32 = 53651;
    try std.testing.expectEqual(expected, result);
}
