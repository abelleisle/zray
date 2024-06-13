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
const utils = @import("utils.zig");

////////////////////////////////////////////////
//                    TYPE                    //
////////////////////////////////////////////////
const Camera = @This();

samples: usize = 10,
maxDepth: isize = 10,
viewport: Viewport,
renderProgress: std.Progress.Node,
pixmap: []Vec3f.Type,

allocator: Allocator,

/// Create the camera struct
pub fn init(allocator: Allocator, settings: CameraSettings) !Camera {
    const vp = Viewport.init(settings);
    const pixmapLen = vp.imageWidth * vp.imageHeight;
    const cam = .{
        .viewport = vp,
        .renderProgress = std.Progress.start(.{}),
        .pixmap = try allocator.alloc(Vec3f.Type, pixmapLen),

        .allocator = allocator,
    };

    std.debug.print("Camera Information:\n", .{});
    std.debug.print("\tID: {d}, {d}\n", .{ cam.viewport.imageWidth, cam.viewport.imageHeight });
    std.debug.print("\tVP: {d}, {d}\n", .{ cam.viewport.viewportWidth, cam.viewport.viewportHeight });
    std.debug.print("\tCamera Center: {}\n", .{cam.viewport.center});
    std.debug.print("\tImage Size (bytes): {}\n", .{pixmapLen * @sizeOf(Vec3f.Type)});

    return cam;
}

/// Destroy the camera object
pub fn deinit(self: *Camera) void {
    self.allocator.free(self.pixmap);
    self.renderProgress.end();
}

/// Given a world, render it.
pub fn render(self: *Camera, world: *const World) !void {
    const pixelProgNode = self.renderProgress.start("Rendering Pixels", self.viewport.imageWidth * self.viewport.imageHeight);

    const pixelSamplesScale: fsize = 1.0 / @as(fsize, @floatFromInt(self.samples));

    for (0..self.viewport.imageHeight) |y| {
        for (0..self.viewport.imageWidth) |x| {
            var pixelColor = Vec3f.Type{ 0, 0, 0 };
            for (0..self.samples) |_| {
                const ray = self.getRay(x, y);
                const sampleColor = rayColor(ray, self.maxDepth, world);
                pixelColor = pixelColor + sampleColor;
            }

            const finalColor = pixelColor * Vec3f.S(pixelSamplesScale);

            try self.writeTo(x, y, finalColor);
            pixelProgNode.completeOne();
        }
    }
    pixelProgNode.end();
}

/// Given a world, render it. This time multi-threaded!
fn renderThreadWorker(self: *Camera, world: *const World, numThreads: usize, index: usize, pixelProgNode: *const std.Progress.Node) !void {
    var pixelCount: usize = 0;
    for (0..self.viewport.imageHeight) |y| {
        for (0..self.viewport.imageWidth) |x| {
            if (pixelCount >= numThreads) pixelCount = 0;
            if (pixelCount == index) {
                try self.renderPixel(world, x, y);
                pixelProgNode.completeOne();
            }
            pixelCount += 1;
        }
    }
}

/// Given a world, render it. This time multi-threaded!
pub fn renderThreaded(self: *Camera, world: *const World, numThreads: usize) !void {
    const pixelProgNode = self.renderProgress.start("Rendering Pixels", self.viewport.imageWidth * self.viewport.imageHeight);

    var threadList = try std.ArrayList(std.Thread).initCapacity(self.allocator, numThreads);
    defer threadList.deinit();

    for (0..numThreads) |idx| {
        // zig fmt: off
        const thread = try std.Thread.spawn(
            .{},
            renderThreadWorker,
            .{
                @as(*Camera, self),
                @as(*const World, world),
                @as(usize, numThreads),
                @as(usize, idx),
                @as(*const std.Progress.Node, &pixelProgNode)
            }
        );
        // zig fmt: on
        try threadList.append(thread);
    }

    for (threadList.items) |t| {
        t.join();
    }

    pixelProgNode.end();
}

/// Given a world, render it.
fn renderPixel(self: *Camera, world: *const World, x: usize, y: usize) !void {
    const pixelSamplesScale: fsize = 1.0 / @as(fsize, @floatFromInt(self.samples));

    var pixelColor = Vec3f.Type{0, 0, 0};
    for (0..self.samples) |_| {
        const ray = self.getRay(x, y);
        const sampleColor = rayColor(ray, self.maxDepth, world);
        pixelColor = pixelColor + sampleColor;
    }

    const finalColor = pixelColor * Vec3f.S(pixelSamplesScale);

    try self.writeTo(x, y, finalColor);
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
fn writeTo(self: *Camera, x: usize, y: usize, color: Vec3f.Type) !void {
    const index = try self.posIndex(x, y);
    self.pixmap[index] = color;
}

/// Read color from specified pixel location
fn readFrom(self: *const Camera, x: usize, y: usize) !Vec3f.Type {
    const index = try self.posIndex(x, y);
    return self.pixmap[index];
}

/// Convert position to index
fn posIndex(self: *const Camera, x: usize, y: usize) !usize {
    if (x >= self.viewport.imageWidth or y >= self.viewport.imageHeight) {
        return error.BadIndexLarge;
    }

    return (x + (y * self.viewport.imageWidth));
}

fn getRay(self: *const Camera, xInt: usize, yInt: usize) Ray {
    const x: fsize = @floatFromInt(xInt);
    const y: fsize = @floatFromInt(yInt);

    const offset = self.sampleSquare();

    const pdu = self.viewport.pixelDeltaU;
    const pdv = self.viewport.pixelDeltaV;

    const xo = pdu * Vec3f.S(x + offset[0]);
    const yo = pdv * Vec3f.S(y + offset[1]);

    const pixelSample = (self.viewport.pixel00Loc + xo) + yo;

    const origin = if (self.viewport.defocusAngle <= 0)
        self.viewport.center
    else
        self.viewport.defocusDiskSample();

    const direction = pixelSample - origin;
    const ray = Ray.init(origin, direction);

    return ray;
}

fn sampleSquare(self: *const Camera) Vec3f.Type {
    _ = self;
    const vec = Vec3f.Type{ utils.randomFloat() - 0.5, utils.randomFloat() - 0.5, 0 };

    return vec;
}

/// Determine the color that a ray should return when cast into the world
fn rayColor(ray: Ray, depth: isize, world: *const World) Vec3f.Type {
    // We start at 1000*epsilon to avoid artifacting due to floating point
    // rounding errors
    const ival = Interval.init(10000 * math.floatEps(fsize), math.inf(fsize));

    // If we're too many rays deep, we can't collect any more light
    if (depth <= 0)
        return Vec3f.S(0);

    // If we intersect with any objects, determine the color returned by the
    // object
    if (world.intersection(ray, ival)) |hr| {
        if (hr.mat.scatter(ray, hr)) |scatter| {
            const rc = rayColor(scatter.scattered, depth - 1, world);
            return scatter.attenuation * rc;
        }
        // This should be unreachable
        return Vec3f.S(0);
    }

    // If we don't hit any object, calculate the color of the sky
    const unitDirection = Vec3f.unit(ray.direction);
    const a = 0.5 * (unitDirection[1] + 1.0);

    const lhs = Vec3f.Type{1.0, 1.0, 1.0} * Vec3f.S(1.0 - a);
    const rhs = Vec3f.Type{0.5, 0.7, 1.0} * Vec3f.S(a);

    return lhs + rhs;
}

/// Camera creation settings
pub const CameraSettings = struct {
    imageWidth: usize,
    imageAspectRatio: fsize,
    lookFrom: Vec3f.Type,
    lookAt: Vec3f.Type,
    upDirection: Vec3f.Type,
    vFOV: fsize,
    defocusAngle: fsize = 0,
    focusDistance: fsize = 10,
};

/// Camera viewport information
const Viewport = struct {
    u: Vec3f.Type,
    v: Vec3f.Type,
    w: Vec3f.Type,

    defocusAngle: fsize,
    defocusDiskU: Vec3f.Type,
    defocusDiskV: Vec3f.Type,

    imageAspectRatio: fsize,

    imageWidth: usize,
    imageHeight: usize,

    imageWidthF: fsize,
    imageHeightF: fsize,

    // Viewport dimensions
    viewportHeight: fsize,
    viewportWidth: fsize,
    center: Vec3f.Type,

    // Find horizontal and vertical viewport vectors
    viewportU: Vec3f.Type,
    viewportV: Vec3f.Type,

    viewportUhalf: Vec3f.Type,
    viewportVhalf: Vec3f.Type,

    // Get the pixel-to-pixel vectors
    pixelDeltaU: Vec3f.Type,
    pixelDeltaV: Vec3f.Type,

    // Find upper-left pixel
    viewportTopLeft: Vec3f.Type,
    pixel00Loc: Vec3f.Type,

    pub fn init(settings: CameraSettings) Viewport {
        const imageWidthF: fsize = @floatFromInt(settings.imageWidth);
        const imageHeightF: fsize = imageWidthF / settings.imageAspectRatio;

        const imageHeight: usize = @intFromFloat(imageHeightF);

        // Viewport dimensions
        // const focalLength = settings.lookFrom.subVec(settings.lookAt).length();
        const theta = utils.degreesToRadians(settings.vFOV);
        const h = math.tan(theta / 2);
        const viewportHeight = 2 * h * settings.focusDistance;
        // const viewportHeight: fsize = 2.0 * h * focalLength;
        // const viewportHeight: fsize = 2.0;
        const viewportWidth: fsize = viewportHeight * (imageWidthF / imageHeightF);
        const center = settings.lookFrom;

        // Calculate U,V,W values for the viewport
        const w = Vec3f.unit(settings.lookFrom - settings.lookAt);
        const u = Vec3f.unit(Vec3f.cross(settings.upDirection, w));
        const v = Vec3f.cross(w, u);

        // Find horizontal and vertical viewport vectors
        const viewportU = u * Vec3f.S(viewportWidth);
        const viewportV = -v * Vec3f.S(viewportHeight);

        const viewportUhalf = viewportU / Vec3f.S(2);
        const viewportVhalf = viewportV / Vec3f.S(2);

        // Get the pixel-to-pixel vectors
        const pixelDeltaU = viewportU / Vec3f.S(imageWidthF);
        const pixelDeltaV = viewportV / Vec3f.S(imageHeightF);

        // Find upper-left pixel
        // const viewportTopLeft = ((center.subVec(focalLengthVec)).subVec(viewportUhalf)).subVec(viewportVhalf);
        const viewportTopLeft = center - (w * Vec3f.S(settings.focusDistance)) - viewportUhalf - viewportVhalf;

        const pixel00Loc = viewportTopLeft + ((pixelDeltaU + pixelDeltaV) * Vec3f.S(0.5));

        const defocusRadius = settings.focusDistance * math.tan(utils.degreesToRadians(settings.defocusAngle / 2));
        const defocusDiskU = u * Vec3f.S(defocusRadius);
        const defocusDiskV = v * Vec3f.S(defocusRadius);

        // Create the actual struct
        return .{
            .u = u,
            .v = v,
            .w = w,

            .defocusAngle = settings.defocusAngle,
            .defocusDiskU = defocusDiskU,
            .defocusDiskV = defocusDiskV,

            .imageAspectRatio = settings.imageAspectRatio,

            .imageWidth = settings.imageWidth,
            .imageHeight = imageHeight,

            .imageWidthF = imageWidthF,
            .imageHeightF = imageHeightF,

            .viewportHeight = viewportHeight,
            .viewportWidth = viewportWidth,
            .center = center,

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

    pub fn defocusDiskSample(self: *const Viewport) Vec3f.Type {
        const p = Vec3f.randomUnitDisk();
        return self.center + (self.defocusDiskU * Vec3f.S(p[1]));
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
