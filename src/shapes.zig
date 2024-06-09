const std = @import("std");
const math = std.math;

const Allocator = std.mem.Allocator;

const Ray = @import("types.zig").Ray;
const Vec = @import("types.zig").Vec3f;
const fsize = @import("types.zig").fsize;

////////////////////////////////////////////////
//                    TYPE                    //
////////////////////////////////////////////////

pub const Shape = struct {
    ptr: *anyopaque,
    allocator: Allocator,

    intersectionFnPtr: *const fn (ptr: *const Shape, ray: Ray) ?fsize,
    deinitFnPtr: *const fn (ptr: *const Shape) void,

    pub fn intersection(self: *const Shape, ray: Ray) ?fsize {
        return self.intersectionFnPtr(self, ray);
    }

    pub fn deinit(self: *const Shape) void {
        self.deinitFnPtr(self);
    }
};

pub const Sphere = struct {
    center: Vec,
    radius: fsize,

    shape: Shape,

    pub fn init(allocator: Allocator, center: Vec, radius: fsize) !*Sphere {
        const sphere = try allocator.create(Sphere);
        const shape = .{ .ptr = sphere, .allocator = allocator, .intersectionFnPtr = intersection, .deinitFnPtr = deinit };
        sphere.* = .{
            .center = center,
            .radius = radius,
            .shape = shape,
        };
        return sphere;
    }

    pub fn deinit(ptr: *const Shape) void {
        const self: *const Sphere = @ptrCast(@alignCast(ptr.ptr));
        ptr.allocator.destroy(self);
    }

    pub fn destroy(self: *Sphere, allocator: Allocator) void {
        allocator.destroy(self);
    }

    pub fn inside(ptr: *const Shape, point: Vec) bool {
        const self: *const Sphere = @ptrCast(@alignCast(ptr.ptr));

        const positionCenter = self.center.subVec(point);
        const distance = positionCenter.dot(positionCenter);

        return distance <= math.pow(fsize, self.radius, 2);
    }

    pub fn intersection(ptr: *const Shape, ray: Ray) ?fsize {
        const self: *const Sphere = @ptrCast(@alignCast(ptr.ptr));

        const oc = self.center.subVec(ray.origin);

        const a = ray.direction.lengthSq();
        const h = ray.direction.dot(oc);
        const c = oc.lengthSq() - (self.radius * self.radius);

        const discriminant = (h * h) - (a * c);
        if (discriminant < 0) {
            return null;
        } else {
            return (h - math.sqrt(discriminant)) / a;
        }
    }

    pub fn format(self: Sphere, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        try writer.print("{}r{d}", .{ self.center, self.radius });
    }
};

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

const testing = std.testing;
const talloc = std.testing.allocator;

////////////////////
// Sphere

test "Create Sphere" {
    const originTest = Vec.init(34, 0.003, -1);
    const radius = 5.6;
    const sphereTest = try Sphere.init(talloc, originTest, radius);
    defer sphereTest.destroy(talloc);

    try testing.expectEqual(5.6, sphereTest.radius);
    try testing.expectEqual(Vec.init(34, 0.003, -1), sphereTest.center);
}

test "Inside Origin" {
    const originTest = Vec.init(0, 0, 0);
    const radius = 1;
    const sphereTest = try Sphere.init(talloc, originTest, radius);
    defer sphereTest.destroy(talloc);

    const ITV = struct { expected: bool, vector: Vec };

    const insideTest = [_]ITV{
        .{ .expected = false, .vector = Vec.init(0, 0, 1.00001) },
        .{ .expected = true, .vector = Vec.init(0, 0, 1.0) },
        .{ .expected = true, .vector = Vec.init(0.577350, -0.577350, 0.577350) },
        .{ .expected = false, .vector = Vec.init(-0.577351, -0.577350, 0.577350) },
    };

    for (insideTest) |i| {
        const e = i.expected;
        const a = sphereTest.inside(i.vector);
        try testing.expectEqual(e, a);
    }
}

test "Inside Moved" {
    const originTest = Vec.init(3.5, 2.4, 5.7);
    const radius = 0.59;
    const sphereTest = try Sphere.init(talloc, originTest, radius);
    defer sphereTest.destroy(talloc);

    const ITV = struct { expected: bool, vector: Vec };

    const insideTest = [_]ITV{
        .{ .expected = true, .vector = Vec.init(3.5, 2.4, 5.7) },
        .{ .expected = true, .vector = Vec.init(3.5, 1.82, 5.7) },
        .{ .expected = false, .vector = Vec.init(0.1, 2.4, 5.7) },
        .{ .expected = true, .vector = originTest.addVec((Vec.init(0.25, 0.8, -2.2).unitVec()).multiply(radius)) },
        .{ .expected = false, .vector = originTest.addVec((Vec.init(0.25, 0.8, -2.2).unitVec()).multiply(radius * 1.0001)) },
    };

    for (insideTest) |i| {
        const e = i.expected;
        const a = sphereTest.inside(i.vector);
        try testing.expectEqual(e, a);
    }
}
