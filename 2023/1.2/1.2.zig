const std = @import("std");

// https://adventofcode.com/2023/day/1
fn solve(input: []const u8) !u32 {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var result: u32 = 0;
    while (lines.next()) |line| {
        var parser = Parser.init(line);
        const parsed = parser.parseFirstLastDigits();
        const first_digit = parsed.first.?;
        const last_digit = parsed.last.?;
        result += first_digit * 10 + last_digit;
    }
    return result;
}

const Parser = struct {
    buf: []const u8,
    pos: usize = 0,

    pub fn init(buf: []const u8) Parser {
        return .{ .buf = buf };
    }

    pub fn parseFirstLastDigits(self: *@This()) struct { first: ?u8, last: ?u8 } {
        const word_digits = &[_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
        var first_digit: ?u8 = null;
        var last_digit: ?u8 = null;

        while (self.pos < self.buf.len) : (self.pos += 1) {
            const current_char = self.buf[self.pos];
            var maybe_digit: ?u8 = null;

            if (std.ascii.isDigit(current_char)) {
                maybe_digit = current_char - '0';
            } else {
                for (word_digits, 0..) |word, i| {
                    if (std.mem.startsWith(u8, self.buf[self.pos..], word)) {
                        maybe_digit = @intCast(i + 1);
                    }
                }
            }

            if (maybe_digit) |digit| {
                if (first_digit == null) {
                    first_digit = digit;
                }
                last_digit = digit;
            }
        }

        return .{ .first = first_digit, .last = last_digit };
    }
};

test "example input" {
    const input = @embedFile("./example-input.txt");
    const result = try solve(input);
    const expected: u32 = 281;
    try std.testing.expectEqual(expected, result);
}

test "real input" {
    const input = @embedFile("./real-input.txt");
    const result = try solve(input);
    const expected: u32 = 53894;
    try std.testing.expectEqual(expected, result);
}
