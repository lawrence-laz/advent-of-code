const std = @import("std");

// https://adventofcode.com/2024/day/3
const Mul = struct {
    const TEMPLATE = "mul(X,Y)";
    const SECOND_NUMBER_INDEX = 6;

    index: usize = 0,
    left_reg: std.BoundedArray(u8, 3) = .{},
    right_reg: std.BoundedArray(u8, 3) = .{},

    fn reset(self: *@This()) void {
        self.index = 0;
        self.left_reg.len = 0;
        self.right_reg.len = 0;
    }

    fn feed(self: *@This(), char: u8) bool {
        const expected_char = TEMPLATE[self.index];
        if (expected_char == 'X') switch (char) {
            '0'...'9' => self.left_reg.append(char) catch unreachable,
            ',' => if (self.left_reg.len > 0) {
                self.index = SECOND_NUMBER_INDEX;
            } else {
                return self.resetAndFeed(char);
            },
            else => return self.resetAndFeed(char),
        } else if (expected_char == 'Y') switch (char) {
            '0'...'9' => self.right_reg.append(char) catch unreachable,
            ')' => if (self.right_reg.len > 0) {
                return true;
            } else {
                return self.resetAndFeed(char);
            },
            else => return self.resetAndFeed(char),
        } else if (char == expected_char) {
            self.index += 1;
        } else {
            return self.resetAndFeed(char);
        }
        return false;
    }

    fn resetAndFeed(self: *@This(), char: u8) bool {
        const try_again = self.index > 0;
        self.reset();
        if (try_again) {
            return self.feed(char);
        } else {
            return false;
        }
    }
};

const Dont = struct {
    const TEMPLATE = "don't()";
    index: usize = 0,
    enabled: bool = false,

    fn feed(self: *@This(), char: u8) bool {
        if (!self.enabled) {
            return false;
        }
        if (char == TEMPLATE[self.index]) {
            self.index += 1;
        } else {
            self.index = 0;
        }
        if (self.index == TEMPLATE.len) {
            return true;
        }
        return false;
    }
};

const Do = struct {
    const TEMPLATE = "do()";
    index: usize = 0,
    enabled: bool = false,

    fn feed(self: *@This(), char: u8) bool {
        if (!self.enabled) {
            return false;
        }
        if (char == TEMPLATE[self.index]) {
            self.index += 1;
        } else {
            self.index = 0;
        }
        if (self.index == TEMPLATE.len) {
            return true;
        }
        return false;
    }
};

const Computer = struct {
    instruction_mul: Mul = .{},
    instruction_do: Do = .{},
    instruction_dont: Dont = .{},

    mul_enabled: bool = true,
    sum: u32 = 0,

    fn execute(self: *Computer, source: []const u8) u32 {
        var stream = std.io.fixedBufferStream(source);
        var reader = stream.reader();
        while (reader.readByte() catch null) |char| {
            if (self.instruction_do.feed(char)) {
                self.mul_enabled = true;
            }
            if (self.instruction_dont.feed(char)) {
                self.mul_enabled = false;
            }
            if (self.instruction_mul.feed(char)) {
                if (self.mul_enabled) {
                    const left_number = std.fmt.parseUnsigned(u32, self.instruction_mul.left_reg.slice(), 10) catch unreachable;
                    const right_number = std.fmt.parseUnsigned(u32, self.instruction_mul.right_reg.slice(), 10) catch unreachable;
                    self.sum += left_number * right_number;
                }
                self.instruction_mul.reset();
            }
        }
        return self.sum;
    }
};

test "example input part1" {
    const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    var computer: Computer = .{};
    const result = computer.execute(input);
    try std.testing.expectEqual(161, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    var computer: Computer = .{};
    const result = computer.execute(input);
    try std.testing.expectEqual(180233229, result);
}

test "example input part2" {
    const input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    var computer: Computer = .{};
    computer.instruction_do.enabled = true;
    computer.instruction_dont.enabled = true;
    const result = computer.execute(input);
    try std.testing.expectEqual(48, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    var computer: Computer = .{};
    computer.instruction_do.enabled = true;
    computer.instruction_dont.enabled = true;
    const result = computer.execute(input);
    try std.testing.expectEqual(95411583, result);
}
