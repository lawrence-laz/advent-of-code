const std = @import("std");

fn solve(input: []const u8) !u32 {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    const red = 12;
    const green = 13;
    const blue = 14;
    var result: u32 = 0;
    game: while (lines.next()) |line| {
        var line_split = std.mem.splitSequence(u8, line, ": ");
        var gameIndex = try std.fmt.parseUnsigned(u32, line_split.first()[5..], 10);
        var draws_string = line_split.next().?;
        var draws = std.mem.tokenizeSequence(u8, draws_string, "; ");
        while (draws.next()) |draw| {
            var cubes = std.mem.tokenizeSequence(u8, draw, ", ");
            while (cubes.next()) |cube| {
                var cube_split = std.mem.splitSequence(u8, cube, " ");
                var count = try std.fmt.parseUnsigned(u32, cube_split.first(), 10);
                var color = cube_split.next().?;
                if (std.mem.eql(u8, color, "red") and count > red or
                    std.mem.eql(u8, color, "blue") and count > blue or
                    std.mem.eql(u8, color, "green") and count > green)
                {
                    continue :game;
                }
            }
        }
        result += gameIndex;
    }
    return result;
}

test "example input" {
    var input = @embedFile("example-input.txt");
    var actual = try solve(input);
    var expected: u32 = 8;
    try std.testing.expectEqual(expected, actual);
}

test "real input" {
    var input = @embedFile("real-input.txt");
    var actual = try solve(input);
    var expected: u32 = 2237;
    try std.testing.expectEqual(expected, actual);
}
