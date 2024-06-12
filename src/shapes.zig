const std = @import("std");
const math = std.math;

const Allocator = std.mem.Allocator;

const types = @import("types.zig");
const Ray = types.Ray;
const Vec3f = types.Vec3f;
const Vec = types.Vec;
const fsize = types.fsize;
const HitRecord = types.HitRecord;
const Interval = types.Interval;

const Scatter = @import("material.zig").Scatter;
const Material = @import("material.zig").Material;

////////////////////////////////////////////////
//                    TYPE                    //
////////////////////////////////////////////////

pub const Shape = struct {
    ptr: *anyopaque,
    allocator: Allocator,

    intersectionFnPtr: *const fn (self: *const Shape, ray: Ray, rayT: Interval) ?HitRecord,
    insideFnPtr: *const fn (self: *const Shape, point: Vec3f) bool,
    deinitFnPtr: *const fn (ptr: *const Shape) void,
    originFnPtr: *const fn (ptr: *const Shape) Vec3f,
    radiusFnPtr: *const fn (ptr: *const Shape) fsize,

    pub fn intersection(self: *const Shape, ray: Ray, rayT: Interval) ?HitRecord {
        return self.intersectionFnPtr(self, ray, rayT);
    }

    pub fn inside(self: *const Shape, point: Vec3f) bool {
        return self.insideFnPtr(self, point);
    }

    pub fn deinit(self: *const Shape) void {
        self.deinitFnPtr(self);
    }

    pub fn origin(self: *const Shape) Vec3f {
        return self.originFnPtr(self);
    }

    pub fn radius(self: *const Shape) fsize {
        return self.radiusFnPtr(self);
    }
};

pub const Sphere = struct {
    center: Vec3f,
    radius: fsize,
    mat: Material,

    shape: Shape,

    pub fn init(allocator: Allocator, center: Vec3f, radius: fsize, mat: Material) !*Sphere {
        const sphere = try allocator.create(Sphere);
        const shape = .{ .ptr = sphere, .allocator = allocator, .intersectionFnPtr = intersection, .insideFnPtr = inside, .deinitFnPtr = deinit, .originFnPtr = origin, .radiusFnPtr = boundingRadius };
        sphere.* = .{
            .center = center,
            .radius = Interval.init(0, math.floatMax(fsize)).clamp(radius),
            .shape = shape,
            .mat = mat,
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

    pub fn inside(ptr: *const Shape, point: Vec3f) bool {
        const self: *const Sphere = @ptrCast(@alignCast(ptr.ptr));

        const positionCenter = self.center - point;
        const distance = Vec.dot(positionCenter, positionCenter);

        return distance <= math.pow(fsize, self.radius, 2);
    }

    pub fn intersection(ptr: *const Shape, ray: Ray, rayT: Interval) ?HitRecord {
        const self: *const Sphere = @ptrCast(@alignCast(ptr.ptr));

        const oc = self.center - ray.origin;

        const a = Vec.lengthSq(ray.direction);
        const h = Vec.dot(ray.direction, oc);
        const c = Vec.lengthSq(oc) - (self.radius * self.radius);

        const discriminant = (h * h) - (a * c);
        if (discriminant < 0) {
            return null;
        }

        const sqrtd = math.sqrt(discriminant);

        // Find nearest root in specified range
        var root = (h - sqrtd) / a;
        if (!rayT.surrounds(root)) {
            root = (h + sqrtd) / a;
            if (!rayT.surrounds(root)) {
                return null;
            }
        }

        const time = root;
        const pos = ray.at(time);
        const outwardNormal = (pos - self.center) / Vec.scalar(@TypeOf(pos), self.radius);
        return HitRecord.init(pos, time, ray, outwardNormal, self.mat);
    }

    pub fn origin(ptr: *const Shape) Vec3f {
        const self: *const Sphere = @ptrCast(@alignCast(ptr.ptr));
        return self.center;
    }

    pub fn boundingRadius(ptr: *const Shape) fsize {
        const self: *const Sphere = @ptrCast(@alignCast(ptr.ptr));
        return self.radius;
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
    const originTest = Vec.vec3f(34, 0.003, -1);
    const radius = 5.6;
    const sphereTest = try Sphere.init(talloc, originTest, radius);
    defer sphereTest.destroy(talloc);

    try testing.expectEqual(5.6, sphereTest.radius);
    try testing.expectEqual(Vec.init(34, 0.003, -1), sphereTest.center);
}

test "Inside Origin" {
    const originTest = Vec.vec3f(0, 0, 0);
    const radius = 1;
    const sphereTest = try Sphere.init(talloc, originTest, radius);
    defer sphereTest.destroy(talloc);

    const ITV = struct { expected: bool, vector: Vec };

    const insideTest = [_]ITV{
        .{ .expected = false, .vector = Vec.vec3f(0, 0, 1.00001) },
        .{ .expected = true, .vector = Vec.vec3f(0, 0, 1.0) },
        .{ .expected = true, .vector = Vec.vec3f(0.577350, -0.577350, 0.577350) },
        .{ .expected = false, .vector = Vec.vec3f(-0.577351, -0.577350, 0.577350) },
    };

    for (insideTest) |i| {
        const e = i.expected;
        const a = sphereTest.shape.inside(i.vector);
        try testing.expectEqual(e, a);
    }
}

test "Inside Moved" {
    const originTest = Vec.vec3f(3.5, 2.4, 5.7);
    const radius = 0.59;
    const sphereTest = try Sphere.init(talloc, originTest, radius);
    defer sphereTest.destroy(talloc);

    const ITV = struct { expected: bool, vector: Vec };

    const insideTest = [_]ITV{
        .{ .expected = true, .vector = Vec.vec3f(3.5, 2.4, 5.7) },
        .{ .expected = true, .vector = Vec.vec3f(3.5, 1.82, 5.7) },
        .{ .expected = false, .vector = Vec.vec3f(0.1, 2.4, 5.7) },
        .{ .expected = true, .vector = originTest.addVec((Vec.vec3f(0.25, 0.8, -2.2).unitVec()).multiply(radius)) },
        .{ .expected = false, .vector = originTest.addVec((Vec.vec3f(0.25, 0.8, -2.2).unitVec()).multiply(radius * 1.0001)) },
    };

    for (insideTest) |i| {
        const e = i.expected;
        const a = sphereTest.shape.inside(i.vector);
        try testing.expectEqual(e, a);
    }
}
