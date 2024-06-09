const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const fs = std.fs;

const PPM = @import("image/ppm.zig");

const types = @import("types.zig");
const Vec3f = types.Vec3f;
const Ray = types.Ray;
const fsize = types.fsize;
const Interval = types.Interval;

const shapes = @import("shapes.zig");
const Shape = shapes.Shape;
const Sphere = shapes.Sphere;

const World = @import("world.zig").World;
const Camera = @import("camera.zig");

/////////////////////////////////////////////////////
//                    CONSTANTS                    //
/////////////////////////////////////////////////////

// Image aspect ratio
const imageAspectRatio: fsize = 16.0 / 9.0;

// Image dimensions
const imageWidth: usize = 800;

/////////////////////////////////////////////////////
//                    FUNCTIONS                    //
/////////////////////////////////////////////////////

pub fn main() !void {
    var arenaAlloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAlloc.deinit();

    const alloc = arenaAlloc.allocator();

    var cam = try Camera.init(alloc, imageWidth, imageAspectRatio);
    defer cam.deinit();

    var world = World.init(alloc);
    defer world.deinit();

    // Create Shapes
    var sp = try Sphere.init(alloc, Vec3f.init(0, 0, -1), 0.5);
    try world.add(sp.shape);

    sp = try Sphere.init(alloc, Vec3f.init(0, -100.5, -1), 100);
    try world.add(sp.shape);

    sp = try shapes.Sphere.init(alloc, Vec3f.init(-2, 2, -5), 1.0);
    try world.add(sp.shape);

    try cam.render(&world);

    var ppm = try cam.createPPM();
    defer ppm.deinit();

    var file = try ppm.render(null);
    defer file.deinit();

    var fsf = try fs.createFileAbsolute("/tmp/demo.ppm", .{});
    defer fsf.close();

    const writtenLen = try fsf.write(file.str());
    if (writtenLen != file.len) {
        return error.WriteSize;
    }
}

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

test {
    @import("std").testing.refAllDecls(@This());
}
