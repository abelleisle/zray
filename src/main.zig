const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;

const fs = std.fs;

const PPM = @import("image/ppm.zig");

const Vec3f = @import("types.zig").Vec3f;
const Ray = @import("types.zig").Ray;
const fsize = @import("types.zig").fsize;

const Sphere = @import("shapes.zig").Sphere;

/////////////////////////////////////////////////////
//                    CONSTANTS                    //
/////////////////////////////////////////////////////

// Image aspect ratio
const imageAspectRatio: fsize = 16.0 / 9.0;

// Image dimensions
const imageWidth: usize = 2560;
const imageHeight: usize = @intFromFloat(imageHeightF);
const imageWidthF: fsize = @floatFromInt(imageWidth);
const imageHeightF: fsize = imageWidthF / imageAspectRatio;

// Viewport dimensions
const focalLength: fsize = 1.0;
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

/////////////////////////////////////////////////////
//                    FUNCTIONS                    //
/////////////////////////////////////////////////////

pub fn skyColor(ray: Ray) Vec3f {
    const sphere = Sphere.init(Vec3f.init(0, 0, -1), 0.5);
    if (sphere.intersect(ray)) {
        return Vec3f.init(1, 0, 0);
    }

    const unitDirection = ray.direction.unitVec();
    const a = 0.5 * (unitDirection.y + 1.0);

    const lhs = Vec3f.init(1.0, 1.0, 1.0).multiply(1.0 - a);
    const rhs = Vec3f.init(0.5, 0.7, 1.0).multiply(a);

    return lhs.addVec(rhs);
}

pub fn main() !void {
    std.debug.print("ID: {d}, {d}\n", .{ imageWidth, imageHeight });
    std.debug.print("VP: {d}, {d}\n", .{ viewportWidth, viewportHeight });
    std.debug.print("Focal Length: {d}\n", .{focalLength});
    std.debug.print("Camera Center: {}\n", .{cameraLocation});

    var arenaAlloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAlloc.deinit();

    const alloc = arenaAlloc.allocator();

    var ppm = try PPM.init(alloc, imageWidth, imageHeight);
    defer ppm.deinit();

    const parentProgNode = std.Progress.start(.{});
    defer parentProgNode.end();

    const pixelProgNode = parentProgNode.start("Rendering Pixels", imageWidth * imageHeight);
    for (0..imageHeight) |Y| {
        const y: fsize = @floatFromInt(Y);
        for (0..imageWidth) |X| {
            const x: fsize = @floatFromInt(X);

            const uDelta = pixelDeltaU.multiply(x);
            const vDelta = pixelDeltaV.multiply(y);

            const pixelCenter = pixel00Loc.addVec(uDelta.addVec(vDelta));
            const rayDirection = pixelCenter.subVec(cameraLocation);
            const ray = Ray.init(cameraLocation, rayDirection);

            const color = skyColor(ray);
            try ppm.writeVecF(X, Y, color);
            pixelProgNode.completeOne();
        }
    }
    pixelProgNode.end();

    var file = try ppm.render(parentProgNode);
    defer file.deinit();

    var fsf = try fs.createFileAbsolute("/tmp/demo.ppm", .{});
    defer fsf.close();

    const fileProgNode = parentProgNode.start("File Writing", 1);
    const writtenLen = try fsf.write(file.str());
    if (writtenLen != file.len) {
        return error.WriteSize;
    }
    fileProgNode.completeOne();
    fileProgNode.end();
}

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

test {
    @import("std").testing.refAllDecls(@This());
}
