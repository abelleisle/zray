const std = @import("std");
const math = std.math;
const fs = std.fs;

const Allocator = std.mem.Allocator;

const PPM = @import("image/ppm.zig");

const types = @import("types.zig");
const fsize = types.fsize;
const Vec3f = types.Vec3f;
const Ray = types.Ray;
const Interval = types.Interval;

const World = @import("world.zig").World;

////////////////////////////////////////////////
//                    TYPE                    //
////////////////////////////////////////////////
const Camera = @This();

viewport: Viewport,
renderProgress: std.Progress.Node,
imageData: []Vec3f,

allocator: Allocator,

/// Create the camera struct
pub fn init(allocator: Allocator, imageWidth: usize, imageAspectRatio: fsize) !Camera {
    const vp = Viewport.init(imageWidth, imageAspectRatio, 1.0);
    const imageDataLen = vp.imageWidth * vp.imageHeight;
    const cam = .{
        .viewport = vp,
        .renderProgress = std.Progress.start(.{}),
        .imageData = try allocator.alloc(Vec3f, imageDataLen),

        .allocator = allocator,
    };

    std.debug.print("Camera Information:\n", .{});
    std.debug.print("\tID: {d}, {d}\n", .{ cam.viewport.imageWidth, cam.viewport.imageHeight });
    std.debug.print("\tVP: {d}, {d}\n", .{ cam.viewport.viewportWidth, cam.viewport.viewportHeight });
    std.debug.print("\tFocal Length: {d}\n", .{cam.viewport.focalLength});
    std.debug.print("\tCamera Center: {}\n", .{cam.viewport.cameraLocation});
    std.debug.print("\tImage Size (bytes): {}\n", .{imageDataLen * @sizeOf(Vec3f)});

    return cam;
}

pub fn deinit(self: *Camera) void {
    self.allocator.free(self.imageData);
    self.renderProgress.end();
}

/// Given a world, render it.
pub fn render(self: *Camera, world: *const World) !void {
    const pixelProgNode = self.renderProgress.start("Rendering Pixels", self.viewport.imageWidth * self.viewport.imageHeight);
    for (0..self.viewport.imageHeight) |Y| {
        const y: fsize = @floatFromInt(Y);
        for (0..self.viewport.imageWidth) |X| {
            const x: fsize = @floatFromInt(X);

            const uDelta = self.viewport.pixelDeltaU.multiply(x);
            const vDelta = self.viewport.pixelDeltaV.multiply(y);

            const pixelCenter = self.viewport.pixel00Loc.addVec(uDelta.addVec(vDelta));
            const rayDirection = pixelCenter.subVec(self.viewport.cameraLocation);
            const ray = Ray.init(self.viewport.cameraLocation, rayDirection);

            const color = rayColor(ray, world);
            try self.writeTo(X, Y, color);
            pixelProgNode.completeOne();
        }
    }
    pixelProgNode.end();
}

/// Create PPM image with camera data in it.
/// Caller owns the PPM and must de-init it
pub fn createPPM(self: *const Camera) !PPM {
    var ppm = try PPM.init(self.allocator, self.viewport.imageWidth, self.viewport.imageHeight);

    for (0..self.viewport.imageHeight) |y| {
        for (0..self.viewport.imageWidth) |x| {
            const color = try self.readFrom(x, y);
            try ppm.writeVecF(x, y, color);
        }
    }

    return ppm;
}

/// Write color to specified pixel
fn writeTo(self: *Camera, x: usize, y: usize, color: Vec3f) !void {
    const index = try self.posIndex(x, y);
    self.imageData[index] = color;
}

/// Read color from specified pixel location
fn readFrom(self: *const Camera, x: usize, y: usize) !Vec3f {
    const index = try self.posIndex(x, y);
    return self.imageData[index];
}

/// Convert position to index
fn posIndex(self: *const Camera, x: usize, y: usize) !usize {
    if (x >= self.viewport.imageWidth or y >= self.viewport.imageHeight) {
        return error.BadIndexLarge;
    }

    return (x + (y * self.viewport.imageWidth));
}

/// Determine the color that a ray should return when cast into the world
fn rayColor(ray: Ray, world: *const World) Vec3f {
    const ival = Interval.init(0, math.inf(fsize));
    if (world.intersection(ray, ival)) |hr| {
        return (hr.normal.add(1.0)).multiply(0.5);
    }

    const unitDirection = ray.direction.unitVec();
    const a = 0.5 * (unitDirection.y + 1.0);

    const lhs = Vec3f.init(1.0, 1.0, 1.0).multiply(1.0 - a);
    const rhs = Vec3f.init(0.5, 0.7, 1.0).multiply(a);

    return lhs.addVec(rhs);
}

/// Camera viewport information
const Viewport = struct {
    imageAspectRatio: fsize,

    imageWidth: usize,
    imageHeight: usize,

    imageWidthF: fsize,
    imageHeightF: fsize,

    // Viewport dimensions
    focalLength: fsize,
    focalLengthVec: Vec3f,
    viewportHeight: fsize,
    viewportWidth: fsize,
    cameraLocation: Vec3f,

    // Find horizontal and vertical viewport vectors
    viewportU: Vec3f,
    viewportV: Vec3f,

    viewportUhalf: Vec3f,
    viewportVhalf: Vec3f,

    // Get the pixel-to-pixel vectors
    pixelDeltaU: Vec3f,
    pixelDeltaV: Vec3f,

    // Find upper-left pixel
    viewportTopLeft: Vec3f,
    pixel00Loc: Vec3f,

    pub fn init(imageWidth: usize, imageAspectRatio: fsize, focalLength: fsize) Viewport {
        const imageWidthF: fsize = @floatFromInt(imageWidth);
        const imageHeightF: fsize = imageWidthF / imageAspectRatio;

        const imageHeight: usize = @intFromFloat(imageHeightF);

        // Viewport dimensions
        const focalLengthVec = Vec3f.init(0, 0, focalLength);
        const viewportHeight: fsize = 2.0;
        const viewportWidth: fsize = viewportHeight * (imageWidthF / imageHeightF);
        const cameraLocation = Vec3f.init(0, 0, 0);

        // Find horizontal and vertical viewport vectors
        const viewportU = Vec3f.init(viewportWidth, 0, 0);
        const viewportV = Vec3f.init(0, -viewportHeight, 0);

        const viewportUhalf = viewportU.divide(2);
        const viewportVhalf = viewportV.divide(2);

        // Get the pixel-to-pixel vectors
        const pixelDeltaU = viewportU.divide(imageWidthF);
        const pixelDeltaV = viewportV.divide(imageHeightF);

        // Find upper-left pixel
        const viewportTopLeft = ((cameraLocation.subVec(focalLengthVec)).subVec(viewportUhalf)).subVec(viewportVhalf);

        const pixel00Loc = viewportTopLeft.addVec((pixelDeltaU.addVec(pixelDeltaV)).multiply(0.5));

        // Create the actual struct
        return .{
            .imageAspectRatio = imageAspectRatio,

            .imageWidth = imageWidth,
            .imageHeight = imageHeight,

            .imageWidthF = imageWidthF,
            .imageHeightF = imageHeightF,

            .focalLength = focalLength,
            .focalLengthVec = focalLengthVec,
            .viewportHeight = viewportHeight,
            .viewportWidth = viewportWidth,
            .cameraLocation = cameraLocation,

            .viewportU = viewportU,
            .viewportV = viewportV,

            .viewportUhalf = viewportUhalf,
            .viewportVhalf = viewportVhalf,

            .pixelDeltaU = pixelDeltaU,
            .pixelDeltaV = pixelDeltaV,

            .viewportTopLeft = viewportTopLeft,
            .pixel00Loc = pixel00Loc,
        };
    }
};

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

const testing = std.testing;
const talloc = testing.allocator;
const shapes = @import("shapes.zig");

test "camera memory handling" {
    const imageAspectRatio: fsize = 1.0;
    const imageWidth: usize = 100;

    var camera = try Camera.init(talloc, imageWidth, imageAspectRatio);
    defer camera.deinit();

    var world = World.init(talloc);
    defer world.deinit();

    // Create Shapes
    var sp = try shapes.Sphere.init(talloc, Vec3f.init(0, 0, -1), 0.5);
    try world.add(sp.shape);

    sp = try shapes.Sphere.init(talloc, Vec3f.init(0, -100.5, -1), 100);
    try world.add(sp.shape);

    try camera.render(&world);

    var ppm = try camera.createPPM();
    defer ppm.deinit();

    var file = try ppm.render(null);
    defer file.deinit();
}
