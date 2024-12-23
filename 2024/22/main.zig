const std = @import("std");

// https://adventofcode.com/2024/day/22

fn solvePart1(input: []const u8) !usize {
    const secret_numbers_count: usize = 2000;
    var initial_secret_number_strings = std.mem.tokenizeScalar(u8, input, '\n');
    var sum_of_2000th_secret_numbers: usize = 0;
    while (initial_secret_number_strings.next()) |initial_secret_numbera_string| {
        const initial_secret_number = try std.fmt.parseInt(usize, initial_secret_numbera_string, 10);
        var new_secret_number = initial_secret_number;
        var i: usize = 0;
        while (i < secret_numbers_count) : (i += 1) {
            new_secret_number = generateSecretNumber(new_secret_number);
        }
        std.log.debug("{d}: {d}", .{ initial_secret_number, new_secret_number });
        sum_of_2000th_secret_numbers += new_secret_number;
    }
    return sum_of_2000th_secret_numbers;
}

fn generateSecretNumber(prev_secret_number: usize) usize {
    var new_secret_number: usize = prune(mix(prev_secret_number * 64, prev_secret_number));
    new_secret_number = prune(mix(@as(usize, @intFromFloat(@floor(@as(f32, @floatFromInt(new_secret_number)) / 32))), new_secret_number));
    new_secret_number = prune(mix(new_secret_number * 2048, new_secret_number));
    return new_secret_number;
}

test generateSecretNumber {
    var secret_number = generateSecretNumber(123);
    try std.testing.expectEqual(15887950, secret_number);
    secret_number = generateSecretNumber(secret_number);
    try std.testing.expectEqual(16495136, secret_number);
    secret_number = generateSecretNumber(secret_number);
    try std.testing.expectEqual(527345, secret_number);
    secret_number = generateSecretNumber(secret_number);
    try std.testing.expectEqual(704524, secret_number);
    secret_number = generateSecretNumber(secret_number);
    try std.testing.expectEqual(1553684, secret_number);
    secret_number = generateSecretNumber(secret_number);
    try std.testing.expectEqual(12683156, secret_number);
    secret_number = generateSecretNumber(secret_number);
    try std.testing.expectEqual(11100544, secret_number);
    secret_number = generateSecretNumber(secret_number);
    try std.testing.expectEqual(12249484, secret_number);
    secret_number = generateSecretNumber(secret_number);
    try std.testing.expectEqual(7753432, secret_number);
    secret_number = generateSecretNumber(secret_number);
    try std.testing.expectEqual(5908254, secret_number);
}

fn mix(left: usize, right: usize) usize {
    return left ^ right;
}

test mix {
    try std.testing.expectEqual(37, mix(42, 15));
}

fn prune(number: usize) usize {
    return number % 16777216;
}

test prune {
    try std.testing.expectEqual(16113920, prune(100000000));
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(input);
    try std.testing.expectEqual(37327623, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(input);
    try std.testing.expectEqual(20506453102, result);
}

const PriceChangeSequence = struct {
    @"1": i32 = 0,
    @"2": i32 = 0,
    @"3": i32 = 0,
    @"4": i32 = 0,

    fn push(self: *@This(), change: i32) void {
        self.@"1" = self.@"2";
        self.@"2" = self.@"3";
        self.@"3" = self.@"4";
        self.@"4" = change;
    }
};

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const secret_numbers_count: usize = 2000;
    var initial_secret_number_strings = std.mem.tokenizeScalar(u8, input, '\n');
    const buyers_count: usize = std.mem.count(u8, input, "\n") + 1;
    var sequences_and_prices: std.AutoArrayHashMapUnmanaged(PriceChangeSequence, []?usize) = .{};
    defer {
        for (sequences_and_prices.values()) |value| {
            allocator.free(value);
        }
        sequences_and_prices.deinit(allocator);
    }

    var buyer_index: usize = 0;
    while (initial_secret_number_strings.next()) |initial_secret_numbera_string| {
        const initial_secret_number = try std.fmt.parseInt(usize, initial_secret_numbera_string, 10);
        var new_secret_number = initial_secret_number;
        var sequence: PriceChangeSequence = .{};
        var i: usize = 0;
        while (i < secret_numbers_count) : (i += 1) {
            const prev_price = new_secret_number % 10;
            new_secret_number = generateSecretNumber(new_secret_number);
            const new_price = new_secret_number % 10;
            sequence.push(@as(i32, @intCast(new_price)) - @as(i32, @intCast(prev_price)));
            if (i >= 3) {
                const result = try sequences_and_prices.getOrPut(allocator, sequence);
                if (!result.found_existing) {
                    result.value_ptr.* = try allocator.alloc(?usize, buyers_count);
                    var j: usize = 0;
                    while (j < buyers_count) : (j += 1) {
                        result.value_ptr.*[j] = null;
                    }
                }
                if (result.value_ptr.*[buyer_index] == null) {
                    result.value_ptr.*[buyer_index] = new_price;
                }
            }
        }
        buyer_index += 1;
    }

    var largest_sum: usize = 0;
    var j: usize = 0;
    for (sequences_and_prices.values()) |prices| {
        j += 1;
        var sum: usize = 0;
        for (prices) |maybe_price| {
            if (maybe_price) |price| sum += price;
        }
        if (sum > largest_sum) {
            largest_sum = sum;
        }
    }

    return largest_sum;
}

test "example input part2" {
    const input =
        \\1
        \\2
        \\3
        \\2024
    ;
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(23, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(2423, result);
}
