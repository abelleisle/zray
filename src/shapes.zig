const std = @import("std");
const math = std.math;

const Ray = @import("types.zig").Ray;
const Vec = @import("types.zig").Vec3f;
const fsize = @import("types.zig").fsize;

////////////////////////////////////////////////
//                    TYPE                    //
////////////////////////////////////////////////

pub const Sphere = struct {
    center: Vec,
    radius: fsize,

    pub fn init(center: Vec, radius: fsize) Sphere {
        return .{ .center = center, .radius = radius };
    }

    pub fn inside(self: Sphere, point: Vec) bool {
        const positionCenter = self.center.subVec(point);
        const distance = positionCenter.dot(positionCenter);

        return distance <= math.pow(fsize, self.radius, 2);
    }

    // pub fn intersection(self: Sphere, ray: Ray) ?fsize {
    //     const oc = self.center.subVec(ray.origin);
    //
    //     const a = ray.direction.dot(ray.direction);
    //     const b = -2.0 * ray.direction.dot(oc);
    //     const c = oc.dot(oc) - (self.radius * self.radius);
    //
    //     const discriminant = (b * b) - (4 * a * c);
    //     if (discriminant < 0) {
    //         return null;
    //     } else {
    //         return ((-b) - math.sqrt(discriminant)) / (2.0 * a);
    //     }
    // }

    pub fn intersection(self: Sphere, ray: Ray) ?fsize {
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

////////////////////
// Sphere

test "Create Sphere" {
    const originTest = Vec.init(34, 0.003, -1);
    const radius = 5.6;
    const sphereTest = Sphere.init(originTest, radius);
    const expectedSphere = Sphere{ .center = Vec.init(34, 0.003, -1), .radius = 5.6 };

    try testing.expectEqual(expectedSphere, sphereTest);
}

test "Inside Origin" {
    const originTest = Vec.init(0, 0, 0);
    const radius = 1;
    const sphereTest = Sphere.init(originTest, radius);

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
    const sphereTest = Sphere.init(originTest, radius);

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
