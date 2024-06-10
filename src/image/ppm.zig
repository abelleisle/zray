const PPM = @This();
const Self = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const String = @import("../types.zig").String;
const Vec3f = @import("../types.zig").Vec3f;
const Vec3i = @import("../types.zig").Vec3i;
const Vec3c = @import("../types.zig").Vec3c;
const fsize = @import("../types.zig").fsize;
const Interval = @import("../types.zig").Interval;

allocator: Allocator,
width: usize,
height: usize,

data: []u8,

/// Creates the PPM image
pub fn init(alloc: Allocator, width: usize, height: usize) !Self {
    const dataLen: usize = width * height * 3;
    var ppm = PPM{ .allocator = alloc, .width = width, .height = height, .data = try alloc.alloc(u8, dataLen) };

    try ppm.fillColor(0, 0, 0);

    return ppm;
}

/// De-inits the PPM image
pub fn deinit(self: *Self) void {
    self.allocator.free(self.data);
}

/// Renders image to string
pub fn render(self: Self, progress: ?std.Progress.Node) !String {
    const fileProg = if (progress) |p|
        p.start("PPM File Render", self.height * self.width)
    else
        null;

    defer if (fileProg) |f| {
        f.end();
    };

    var str = String.init(self.allocator);
    var tmp = String.init(self.allocator);
    defer tmp.deinit();

    // Fill the string with the magic header
    try str.fmt("P3\n{} {}\n255\n", .{ self.width, self.height });

    for (0..self.height) |y| {
        for (0..self.width) |x| {
            const index = try self.posIndex(x, y);
            const r = self.data[index + 0];
            const g = self.data[index + 1];
            const b = self.data[index + 2];
            try tmp.fmt("{d} {d} {d} ", .{ r, g, b });
            try str.append(tmp.str());
            if (fileProg) |f| {
                f.completeOne();
            }
        }
        try str.append("\n");
    }

    return str;
}

/// Fill the entire image with a specified color
pub fn fillColor(self: *Self, r: u8, g: u8, b: u8) !void {
    for (0..self.height) |y| {
        for (0..self.width) |x| {
            try self.writeTo(x, y, r, g, b);
        }
    }
}

/// Fill the image with the demo image
pub fn fillDemo(self: *Self) !void {
    const w: fsize = @floatFromInt(self.width - 1);
    const h: fsize = @floatFromInt(self.height - 1);
    for (0..self.height) |y| {
        const Y: fsize = @floatFromInt(y);
        for (0..self.width) |x| {
            const X: fsize = @floatFromInt(x);

            const color = Vec3f.init(X / w, Y / h, 0.0);

            try self.writeVecF(x, y, color);
        }
    }
}

/// Write vec with 0 - 1 precision to coordinate
pub fn writeVecF(self: *Self, x: usize, y: usize, color: Vec3f) !void {
    const c = convertFloatToInt(color);

    try self.writeTo(x, y, c.x, c.y, c.z);
}

/// Write vec with 0 - 255 integer precision to coordinate
pub fn writeVecC(self: *Self, x: usize, y: usize, color: Vec3c) !void {
    const r = color.x;
    const g = color.y;
    const b = color.z;

    try self.writeTo(x, y, r, g, b);
}

/// Write color to specified index
fn writeTo(self: *Self, x: usize, y: usize, r: u8, g: u8, b: u8) !void {
    const index = try self.posIndex(x, y);
    self.data[index + 0] = r;
    self.data[index + 1] = g;
    self.data[index + 2] = b;
}

/// Convert position to index
fn posIndex(self: Self, x: usize, y: usize) !usize {
    if (x >= self.width or y >= self.height) {
        return error.BadIndexLarge;
    }

    return (x + (y * self.width)) * 3;
}

/// Converts 0-1 floats vectors to 0-255 u8 vectors
fn convertFloatToInt(color: Vec3f) Vec3c {
    const r = color.x;
    const g = color.y;
    const b = color.z;

    const intensity = Interval.init(0.000, 0.999);
    const ir: u8 = @intFromFloat(256 * intensity.clamp(r));
    const ig: u8 = @intFromFloat(256 * intensity.clamp(g));
    const ib: u8 = @intFromFloat(256 * intensity.clamp(b));

    return Vec3c.init(ir, ig, ib);
}
