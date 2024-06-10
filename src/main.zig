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

const material = @import("material.zig");
const Material = material.Material;

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
    cam.samples = 10;
    cam.maxDepth = 50;

    var world = World.init(alloc);
    defer world.deinit();

    // Create materials
    const mGround = Material{ .Lambertain = material.Lambertain.init(Vec3f.init(0.8, 0.8, 0.0)) };
    const mCenter = Material{ .Lambertain = material.Lambertain.init(Vec3f.init(0.1, 0.2, 0.6)) };
    const mLeft = Material{ .Metal = material.Metal.init(Vec3f.init(0.8, 0.8, 0.8)) };
    const mRight = Material{ .Metal = material.Metal.init(Vec3f.init(0.8, 0.6, 0.2)) };

    // Create Shapes
    var sp = try Sphere.init(alloc, Vec3f.init(0, -100.5, -1), 100, mGround);
    try world.add(sp.shape);

    sp = try Sphere.init(alloc, Vec3f.init(0, 0, -1.2), 0.5, mCenter);
    try world.add(sp.shape);

    sp = try Sphere.init(alloc, Vec3f.init(-1, 0, -1), 0.5, mLeft);
    try world.add(sp.shape);

    sp = try Sphere.init(alloc, Vec3f.init(1, 0, -1), 0.5, mRight);
    try world.add(sp.shape);

    try cam.render(&world);

    var ppm = try cam.createPPM();
    defer ppm.deinit();

    var file = try ppm.render(cam.renderProgress);
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
