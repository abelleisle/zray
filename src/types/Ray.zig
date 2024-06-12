////////////////////////////////////////////////
//                    TYPE                    //
////////////////////////////////////////////////

pub fn ray(comptime T: type, comptime TimeT: type) type {
    return struct {
        origin: T,
        direction: T,

        const Ray = @This();

        /// Creates a Ray object
        pub inline fn init(origin: T, direction: T) Ray {
            return .{ .origin = origin, .direction = direction };
        }

        /// Obtains the destination of the ray after a specified amount of time
        pub inline fn at(self: Ray, time: TimeT) T {
            return self.origin.addVec(self.direction.multiply(time));
        }
    };
}

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

const std = @import("std");
const math = std.math;
const testing = std.testing;

const VT = @import("../types.zig").fsize;
const vf = @import("../types.zig").Vec3f;
const rf = ray(vf, VT);

test "Ray init" {
    const testVecO = vf.init(34.2, 54.2, 43.4);
    const testVecD = vf.init(0.04, 0.0, -2.2);
    const testRay = rf.init(testVecO, testVecD);
    const expectedO = .{ .x = 34.2, .y = 54.2, .z = 43.4 };
    const expectedD = .{ .x = 0.04, .y = 0.0, .z = -2.2 };
    try testing.expectEqual(testRay.origin.x, expectedO.x);
    try testing.expectEqual(testRay.origin.y, expectedO.y);
    try testing.expectEqual(testRay.origin.z, expectedO.z);
    try testing.expectEqual(testRay.direction.x, expectedD.x);
    try testing.expectEqual(testRay.direction.y, expectedD.y);
    try testing.expectEqual(testRay.direction.z, expectedD.z);
}

test "Ray at simple" {
    const testRayO = vf.init(2.334, 3.14, -1.0);
    const testRayD = vf.init(5.7, 0.0, 0.0);
    const testTime = 1.0;
    const testRay = rf.init(testRayO, testRayD);
    const expectedAt = vf.init(8.034, 3.14, -1.0);
    const actualAt = testRay.at(testTime);
    try testing.expectEqual(expectedAt, actualAt);
}

test "Ray at complicated" {
    const testRayO = vf.init(9.34, 23.1, 89722.3);
    const testRayD = vf.init(1.9345, -93842.3, 7094.1);
    const testTime = 45.0001;
    const testRay = rf.init(testRayO, testRayD);
    const expectedAt = vf.init(96.39269, -4222889.78423, 409007.50941);
    const actualAt = testRay.at(testTime);

    try testing.expect(math.approxEqRel(VT, expectedAt.x, actualAt.x, 0.0005));
    try testing.expect(math.approxEqRel(VT, expectedAt.y, actualAt.y, 0.0005));
    try testing.expect(math.approxEqRel(VT, expectedAt.z, actualAt.z, 0.0005));
}
