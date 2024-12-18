const std = @import("std");

// https://adventofcode.com/2024/day/17

const Computer = struct {
    reg_a: usize,
    reg_b: usize,
    reg_c: usize,
    program: std.BoundedArray(u3, 20) = .{},
    instruction_pointer: usize = 0,
    out: std.ArrayListUnmanaged(u8) = .{},

    fn runInstruction(self: *Computer, allocator: std.mem.Allocator) !bool {
        const instruction = self.read() orelse return false;
        switch (instruction) {
            0 => {
                self.reg_a /= std.math.pow(usize, 2, self.readComboOperand() orelse return false);
            },
            1 => {
                self.reg_b ^= self.read() orelse return false;
            },
            2 => {
                self.reg_b = (self.readComboOperand() orelse return false) % 8;
            },
            3 => {
                const operand = self.read() orelse return false;
                if (self.reg_a != 0) {
                    self.instruction_pointer = operand;
                }
            },
            4 => {
                self.reg_b ^= self.reg_c;
                _ = self.read();
            },
            5 => {
                try self.out.appendSlice(allocator, try std.fmt.allocPrint(
                    allocator,
                    "{d}",
                    .{(self.readComboOperand() orelse return false) % 8},
                ));
            },
            6 => {
                self.reg_b = self.reg_a / std.math.pow(usize, 2, self.readComboOperand() orelse return false);
            },
            7 => {
                self.reg_c = self.reg_a / std.math.pow(usize, 2, self.readComboOperand() orelse return false);
            },
        }

        return true;
    }

    fn readComboOperand(self: *Computer) ?usize {
        const operand = self.read() orelse return null;
        return switch (operand) {
            0, 1, 2, 3 => operand,
            4 => self.reg_a,
            5 => self.reg_b,
            6 => self.reg_c,
            7 => unreachable,
        };
    }

    fn read(self: *Computer) ?u3 {
        if (self.isEndOfProgram()) return null;
        const value = self.program.slice()[self.instruction_pointer];
        self.instruction_pointer += 1;
        return value;
    }

    fn isEndOfProgram(self: Computer) bool {
        return self.instruction_pointer >= self.program.slice().len;
    }
};

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var lines = std.mem.tokenize(u8, input, "\n");
    var computer: Computer = .{
        .reg_a = try std.fmt.parseInt(usize, lines.next().?[12..], 10),
        .reg_b = try std.fmt.parseInt(usize, lines.next().?[12..], 10),
        .reg_c = try std.fmt.parseInt(usize, lines.next().?[12..], 10),
    };

    var instructions = std.mem.tokenize(u8, lines.next().?[9..], ",");
    while (instructions.next()) |instruction| {
        try computer.program.append(try std.fmt.parseInt(u3, instruction, 10));
    }

    while (try computer.runInstruction(allocator)) {}

    return try computer.out.toOwnedSlice(allocator);
}

test "example input part1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(arena.allocator(), input);
    try std.testing.expectEqualSlices(u8, "4635635210", result);
}

test "real input part1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(arena.allocator(), input);
    try std.testing.expectEqualSlices(u8, "315374275", result);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var lines = std.mem.tokenize(u8, input, "\n");
    _ = lines.next(); // Reg A does not matter.
    _ = lines.next(); // Reg B is 0.
    _ = lines.next(); // Reg C is 0.

    var instructions = std.mem.tokenize(u8, lines.next().?[9..], ",");
    var program_source: std.ArrayListUnmanaged(u8) = .{};
    var program: std.ArrayListUnmanaged(u3) = .{};
    while (instructions.next()) |instruction| {
        try program_source.append(allocator, instruction[0]);
        try program.append(allocator, try std.fmt.parseInt(u3, instruction, 10));
    }

    std.mem.reverse(u8, program_source.items);

    var frozen: usize = 0;
    while (true) {
        const max: usize = (frozen << 3) + 9000;
        const min: usize = (frozen << 3) + 0;

        var i = min;
        while (i < max) : (i += 1) {
            var computer: Computer = .{
                .reg_a = i,
                .reg_b = 0,
                .reg_c = 0,
            };
            try computer.program.appendSlice(program.items);
            while (try computer.runInstruction(allocator)) {}
            std.mem.reverse(u8, computer.out.items);
            if (std.mem.eql(u8, computer.out.items, program_source.items)) {
                return i;
            }

            if (std.mem.startsWith(u8, program_source.items, computer.out.items)) {
                frozen = i;
                break;
            }
        }
    }

    return 0;
}

test "real input part2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(arena.allocator(), input);
    try std.testing.expectEqual(190593310997519, result);
}
