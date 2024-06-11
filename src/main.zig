const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const fs = std.fs;

const PPM = @import("image/ppm.zig");

const utils = @import("utils.zig");

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

// Camera Settings
const cSettings = Camera.CameraSettings{
    .lookFrom = Vec3f.init(13, 2, 3),
    .lookAt = Vec3f.init(0, 0, 0),
    .imageWidth = 1200,
    .imageAspectRatio = 16.0 / 9.0,
    .vFOV = 20.0,
    .upDirection = Vec3f.init(0, 1, 0),
    .defocusAngle = 0.6,
    .focusDistance = 10.0,
};

/////////////////////////////////////////////////////
//                    FUNCTIONS                    //
/////////////////////////////////////////////////////

pub fn createRandomWorld(alloc: Allocator, world: *World) !void {
    { // Ground
        const mat = Material{ .Lambertain = material.Lambertain.init(Vec3f.init(0.5, 0.5, 0.5)) };
        const sp = try Sphere.init(alloc, Vec3f.init(0, -1000, 0), 1000, mat);
        try world.add(sp.shape);
    }

    var A: isize = -11;
    while (A <= 11) : (A += 1) {
        const a: fsize = @floatFromInt(A);
        var B: isize = -11;
        while (B <= 11) : (B += 1) {
            const b: fsize = @floatFromInt(B);

            // const radius = utils.randomFloatRange(0.1, 0.4);
            const radius = 0.2;
            const sphereCenter = Vec3f.init(
                a + 0.9 * utils.randomFloat(),
                radius,
                b + 0.9 * utils.randomFloat(),
            );

            const chooseMat = utils.randomFloat();
            if ((sphereCenter.subVec(Vec3f.init(4, radius, 0))).length() > 0.9) {
                if (chooseMat < 0.8) {
                    // Diffuse
                    const albedo = Vec3f.random().multiplyVec(Vec3f.random());
                    const mat = Material{ .Lambertain = material.Lambertain.init(albedo) };
                    const sp = try Sphere.init(alloc, sphereCenter, radius, mat);
                    try world.add(sp.shape);
                } else if (chooseMat < 0.95) {
                    // Metal
                    const albedo = Vec3f.randomRange(0.5, 1.0);
                    const fuzz = utils.randomFloatRange(0.0, 0.5);
                    const mat = Material{ .Metal = material.Metal.init(albedo, fuzz) };
                    const sp = try Sphere.init(alloc, sphereCenter, radius, mat);
                    try world.add(sp.shape);
                } else {
                    // Glass
                    const mat = Material{ .Dielectric = material.Dielectric.init(1.5) };
                    const sp = try Sphere.init(alloc, sphereCenter, radius, mat);
                    try world.add(sp.shape);
                }
            }
        }
    }

    { // Center
        const mat = Material{ .Dielectric = material.Dielectric.init(1.5) };
        const sp = try Sphere.init(alloc, Vec3f.init(0, 1, 0), 1.0, mat);
        try world.add(sp.shape);
    }
    { // Left
        const mat = Material{ .Lambertain = material.Lambertain.init(Vec3f.init(0.4, 0.2, 0.1)) };
        const sp = try Sphere.init(alloc, Vec3f.init(-4, 1, 0), 1.0, mat);
        try world.add(sp.shape);
    }
    { // Right
        const mat = Material{ .Metal = material.Metal.init(Vec3f.init(0.7, 0.6, 0.5), 0.0) };
        const sp = try Sphere.init(alloc, Vec3f.init(4, 1, 0), 1.0, mat);
        try world.add(sp.shape);
    }
}

pub fn main() !void {
    var arenaAlloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAlloc.deinit();

    const alloc = arenaAlloc.allocator();

    var cam = try Camera.init(alloc, cSettings);
    defer cam.deinit();
    cam.samples = 1;
    cam.maxDepth = 50;

    var world = World.init(alloc);
    defer world.deinit();

    try createRandomWorld(alloc, &world);

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
