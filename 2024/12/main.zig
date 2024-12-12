const std = @import("std");

// https://adventofcode.com/2024/day/12

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn mul(self: Vec2, number: i32) Vec2 {
        return .{ .x = self.x * number, .y = self.y * number };
    }

    pub fn eql(self: Vec2, other: Vec2) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Grid = struct {
    slice: []u8,
    width: usize,
    height: usize,

    const NeighboursIter = struct {
        center: Vec2,
        grid: *const Grid,
        index: usize,

        pub fn next(self: *NeighboursIter) ?Vec2 {
            const neighbour_pos = self.nextUnsafe();
            return if (self.grid.contains(neighbour_pos)) neighbour_pos else self.next();
        }

        pub fn nextUnsafe(self: *NeighboursIter) ?Vec2 {
            const neighbour_pos = switch (self.index) {
                0 => self.center.add(.{ .x = 1, .y = 0 }),
                1 => self.center.add(.{ .x = 0, .y = -1 }),
                2 => self.center.add(.{ .x = -1, .y = 0 }),
                3 => self.center.add(.{ .x = 0, .y = 1 }),
                else => return null,
            };
            self.index += 1;
            return neighbour_pos;
        }
    };

    fn neighbours(self: *const @This(), pos: Vec2) NeighboursIter {
        return .{ .center = pos, .grid = self, .index = 0 };
    }

    fn indexToPos(self: @This(), index: usize) Vec2 {
        return .{ .x = @intCast(index % self.width), .y = @intCast(index / self.width) };
    }

    fn get(self: @This(), pos: Vec2) ?u8 {
        if (pos.x < 0 or pos.x >= self.width or pos.y < 0 or pos.y >= self.height) {
            return null;
        }
        const y: usize = @intCast(pos.y);
        const x: usize = @intCast(pos.x);
        const i: usize = y * self.width + x;
        if (i < 0 or i >= self.slice.len) {
            return null;
        }
        return self.slice[i];
    }

    fn set(self: *@This(), pos: Vec2, value: u8) void {
        if (pos.x < 0 or pos.x >= self.width or pos.y < 0 or pos.y >= self.height) return;
        const y: usize = @intCast(pos.y);
        const x: usize = @intCast(pos.x);
        self.slice[y * self.width + x] = value;
    }

    fn contains(self: @This(), pos: Vec2) bool {
        return pos.x >= 0 and pos.x < self.width and pos.y >= 0 and pos.y < self.height;
    }
};

const Region = struct { plant: u8, area: usize, perimeter: usize, corners: usize };

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !usize {
    const input_single_line: []u8 = try allocator.alloc(u8, std.mem.replacementSize(u8, input, "\n", ""));
    defer allocator.free(input_single_line);
    const height = std.mem.replace(u8, input, "\n", "", input_single_line);
    const width = input_single_line.len / height;
    const grid: Grid = .{ .slice = input_single_line, .width = width, .height = height };

    var regions: std.ArrayListUnmanaged(Region) = .{};
    defer regions.deinit(allocator);
    var visited: std.AutoArrayHashMapUnmanaged(Vec2, void) = .{};
    defer visited.deinit(allocator);
    var visiting: std.AutoArrayHashMapUnmanaged(Vec2, void) = .{};
    defer visiting.deinit(allocator);
    var i: usize = 0;
    while (i < input_single_line.len) : (i += 1) {
        visiting.clearRetainingCapacity();

        const start_pos = grid.indexToPos(i);
        if (visited.contains(start_pos)) continue;

        const plant = grid.get(start_pos).?;
        var region: Region = .{ .plant = plant, .perimeter = 0, .area = 0, .corners = 0 };

        try visiting.put(allocator, start_pos, {});
        while (visiting.popOrNull()) |pos| {
            if (visited.contains(pos.key)) continue;
            var neighbours = grid.neighbours(pos.key);
            while (neighbours.nextUnsafe()) |neighbour_pos| {
                const maybe_neighbour_plant = grid.get(neighbour_pos);
                if (maybe_neighbour_plant) |neighbour_plant| {
                    if (plant == neighbour_plant) {
                        try visiting.put(allocator, neighbour_pos, {});
                    } else {
                        region.perimeter += 1;
                    }
                } else {
                    region.perimeter += 1;
                }
            }
            try visited.put(allocator, pos.key, {});
            region.area += 1;
        }
        try regions.append(allocator, region);
    }

    var price: usize = 0;
    for (regions.items) |region| {
        std.log.debug(
            "'{c}' price {d} * {d} = {d}",
            .{ region.plant, region.area, region.perimeter, region.area * region.perimeter },
        );
        price += region.area * region.perimeter;
    }

    return price;
}

test "example input part1" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(1930, result);
}

test "real input part1" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(1467094, result);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const input_single_line: []u8 = try allocator.alloc(u8, std.mem.replacementSize(u8, input, "\n", ""));
    defer allocator.free(input_single_line);
    const height = std.mem.replace(u8, input, "\n", "", input_single_line);
    const width = input_single_line.len / height;
    const grid: Grid = .{ .slice = input_single_line, .width = width, .height = height };

    var regions: std.ArrayListUnmanaged(Region) = .{};
    defer regions.deinit(allocator);
    var visited: std.AutoArrayHashMapUnmanaged(Vec2, void) = .{};
    defer visited.deinit(allocator);
    var visiting: std.AutoArrayHashMapUnmanaged(Vec2, void) = .{};
    defer visiting.deinit(allocator);
    var i: usize = 0;
    while (i < input_single_line.len) : (i += 1) {
        visiting.clearRetainingCapacity();

        const start_pos = grid.indexToPos(i);
        if (visited.contains(start_pos)) continue;

        const plant = grid.get(start_pos).?;
        var region: Region = .{ .plant = plant, .perimeter = 0, .area = 0, .corners = 0 };

        try visiting.put(allocator, start_pos, {});
        while (visiting.popOrNull()) |pos| {
            if (visited.contains(pos.key)) continue;
            var neighbours = grid.neighbours(pos.key);
            while (neighbours.nextUnsafe()) |neighbour_pos| {
                const maybe_neighbour_plant = grid.get(neighbour_pos);
                if (maybe_neighbour_plant) |neighbour_plant| {
                    if (plant == neighbour_plant) {
                        try visiting.put(allocator, neighbour_pos, {});
                    }
                }
            }
            const e_same = if (grid.get(pos.key.add(.{ .x = 1, .y = 0 }))) |other| other == plant else false;
            const ne_same = if (grid.get(pos.key.add(.{ .x = 1, .y = -1 }))) |other| other == plant else false;
            const n_same = if (grid.get(pos.key.add(.{ .x = 0, .y = -1 }))) |other| other == plant else false;
            const nw_same = if (grid.get(pos.key.add(.{ .x = -1, .y = -1 }))) |other| other == plant else false;
            const w_same = if (grid.get(pos.key.add(.{ .x = -1, .y = 0 }))) |other| other == plant else false;
            const sw_same = if (grid.get(pos.key.add(.{ .x = -1, .y = 1 }))) |other| other == plant else false;
            const s_same = if (grid.get(pos.key.add(.{ .x = 0, .y = 1 }))) |other| other == plant else false;
            const se_same = if (grid.get(pos.key.add(.{ .x = 1, .y = 1 }))) |other| other == plant else false;
            if (!w_same and !n_same) region.corners += 1;
            if (!e_same and !n_same) region.corners += 1;
            if (!w_same and !s_same) region.corners += 1;
            if (!e_same and !s_same) region.corners += 1;
            if (w_same and !nw_same and n_same) region.corners += 1;
            if (e_same and !ne_same and n_same) region.corners += 1;
            if (w_same and !sw_same and s_same) region.corners += 1;
            if (e_same and !se_same and s_same) region.corners += 1;
            try visited.put(allocator, pos.key, {});
            region.area += 1;
        }
        try regions.append(allocator, region);
    }

    var price: usize = 0;
    for (regions.items) |region| {
        std.log.debug(
            "'{c}' price {d} * {d} = {d}",
            .{ region.plant, region.area, region.corners, region.area * region.corners },
        );
        price += region.area * region.corners;
    }

    return price;
}

test "example input part2" {
    const input = @embedFile("./example-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(1206, result);
}

test "real input part2" {
    const input = @embedFile("./real-input.txt");
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(881182, result);
}
