const std = @import("std");

fn solve(input: []const u8) !u32 {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var result: u32 = 0;
    while (lines.next()) |line| {
        var line_split = std.mem.splitSequence(u8, line, ": ");
        var gameIndex = try std.fmt.parseUnsigned(u32, line_split.first()[5..], 10);
        _ = gameIndex; //
        var draws_string = line_split.next().?;
        var draws = std.mem.tokenizeSequence(u8, draws_string, "; ");
        var red: u32 = 0;
        var green: u32 = 0;
        var blue: u32 = 0;
        while (draws.next()) |draw| {
            var cubes = std.mem.tokenizeSequence(u8, draw, ", ");
            while (cubes.next()) |cube| {
                var cube_split = std.mem.splitSequence(u8, cube, " ");
                var count = try std.fmt.parseUnsigned(u32, cube_split.first(), 10);
                var color = cube_split.next().?;
                if (std.mem.eql(u8, color, "red") and count > red) {
                    red = count;
                } else if (std.mem.eql(u8, color, "green") and count > green) {
                    green = count;
                } else if (std.mem.eql(u8, color, "blue") and count > blue) {
                    blue = count;
                }
            }
        }
        result += red * green * blue;
    }
    return result;
}

test "example input" {
    var input = @embedFile("example-input.txt");
    var actual = try solve(input);
    var expected: u32 = 2286;
    try std.testing.expectEqual(expected, actual);
}

test "real input" {
    var input = @embedFile("real-input.txt");
    var actual = try solve(input);
    var expected: u32 = 66681;
    try std.testing.expectEqual(expected, actual);
}
