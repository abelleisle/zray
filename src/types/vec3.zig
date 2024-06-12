const std = @import("std");
const math = std.math;

const utils = @import("../utils.zig");

////////////////////////////////////////////////
//                    TYPE                    //
////////////////////////////////////////////////

pub fn vec3(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        const Vec = @This();

        pub inline fn init(x: T, y: T, z: T) Vec {
            return .{ .x = x, .y = y, .z = z };
        }

        pub inline fn random() Vec {
            return .{
                .x = utils.randomFloat(),
                .y = utils.randomFloat(),
                .z = utils.randomFloat(),
            };
        }

        pub inline fn randomRange(min: T, max: T) Vec {
            return .{
                .x = utils.randomFloatRange(min, max),
                .y = utils.randomFloatRange(min, max),
                .z = utils.randomFloatRange(min, max),
            };
        }

        pub inline fn randomUnitSphere() Vec {
            while (true) {
                const v = Vec.randomRange(-1, 1);
                if (v.lengthSq() < 1) return v;
            }
        }

        pub inline fn randomUnitVector() Vec {
            return Vec.randomUnitSphere().unitVec();
        }

        pub inline fn randomUnitDisk() Vec {
            while (true) {
                const d = Vec.init(utils.randomFloatRange(-1, 1), utils.randomFloatRange(-1, 1), 0);
                if (d.lengthSq() < 1) return d;
            }
        }

        pub inline fn randomHemisphere(normal: Vec) Vec {
            const v = Vec.randomUnitVector();
            return if (v.dot(normal) > 0.0) v else v.negate();
        }

        pub inline fn negate(self: Vec) Vec {
            return Vec.init(-self.x, -self.y, -self.z);
        }

        pub fn length(self: Vec) T {
            return math.sqrt(self.lengthSq());
        }

        pub fn lengthSq(self: Vec) T {
            return (self.x * self.x) + (self.y * self.y) + (self.z * self.z);
        }

        pub inline fn add(self: Vec, scalar: T) Vec {
            return Vec.init(self.x + scalar, self.y + scalar, self.z + scalar);
        }

        pub inline fn sub(self: Vec, scalar: T) Vec {
            return self.add(-scalar);
        }

        pub inline fn multiply(self: Vec, scalar: T) Vec {
            return Vec.init(self.x * scalar, self.y * scalar, self.z * scalar);
        }

        pub inline fn divide(self: Vec, scalar: T) Vec {
            if (scalar == 0) {
                math.raiseDivByZero();
            }
            return Vec.init(self.x / scalar, self.y / scalar, self.z / scalar);
        }

        pub fn unitVec(self: Vec) Vec {
            return self.divide(self.length());
        }

        pub inline fn addVec(self: Vec, rhs: Vec) Vec {
            return Vec.init(self.x + rhs.x, self.y + rhs.y, self.z + rhs.z);
        }

        pub inline fn subVec(self: Vec, rhs: Vec) Vec {
            return Vec.init(self.x - rhs.x, self.y - rhs.y, self.z - rhs.z);
        }

        pub inline fn multiplyVec(self: Vec, rhs: Vec) Vec {
            return Vec.init(self.x * rhs.x, self.y * rhs.y, self.z * rhs.z);
        }

        pub inline fn dot(self: Vec, rhs: Vec) T {
            return (self.x * rhs.x) + (self.y * rhs.y) + (self.z * rhs.z);
        }

        pub inline fn cross(lhs: Vec, rhs: Vec) Vec {
            return Vec.init(lhs.y * rhs.z - lhs.z * rhs.y, lhs.z * rhs.x - lhs.x * rhs.z, lhs.x * rhs.y - lhs.y * rhs.x);
        }

        pub inline fn distance(lhs: Vec, rhs: Vec) T {
            return math.sqrt(math.pow(T, (rhs.x - lhs.x), 2) +
                math.pow(T, (rhs.y - lhs.y), 2) +
                math.pow(T, (rhs.z - lhs.z), 2));
        }

        pub inline fn reflect(self: Vec, normal: Vec) Vec {
            return self.subVec(normal.multiply(2 * self.dot(normal)));
        }

        pub inline fn refract(uv: Vec, normal: Vec, etaiOverEtat: T) Vec {
            const cosTheta = @min(uv.negate().dot(normal), 1.0);
            const rOutPerp = (uv.addVec(normal.multiply(cosTheta))).multiply(etaiOverEtat);
            const rOutParallel = normal.multiply(-math.sqrt(@abs(1.0 - rOutPerp.lengthSq())));
            return rOutPerp.addVec(rOutParallel);
        }

        pub inline fn nearZero(self: Vec) bool {
            const tolerance = math.floatEps(T);
            const xClose = math.approxEqAbs(T, self.x, 0, tolerance);
            const yClose = math.approxEqAbs(T, self.y, 0, tolerance);
            const zClose = math.approxEqAbs(T, self.z, 0, tolerance);
            return xClose and yClose and zClose;
        }

        pub fn format(self: Vec, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;

            try writer.print("({d}, {d}, {d})", .{ self.x, self.y, self.z });
        }
    };
}

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

const testing = std.testing;

const vf = vec3(f32);
const VT = f32;

test "Vec init" {
    const testVec = vf.init(4.6, -9.5, 0.1);
    const expected = .{ .x = 4.6, .y = -9.5, .z = 0.1 };
    try testing.expectEqual(expected.x, testVec.x);
    try testing.expectEqual(expected.y, testVec.y);
    try testing.expectEqual(expected.z, testVec.z);
}

test "Vec negate" {
    const testVec = vf.init(-23424.2, 75.2, 128482.8);
    const expected = vf.init(23424.2, -75.2, -128482.8);
    const actual = testVec.negate();
    try testing.expectEqual(expected, actual);
}

test "Vec length" {
    const testVec = vf.init(3.5, 24.0, -1.0);
    const expected: VT = 24.27447;
    const actual: VT = testVec.length();
    try testing.expect(math.approxEqRel(VT, expected, actual, 0.0000001));

    const expectedUnit = vf.init(0.144184, 0.988693, -0.0411955);
    const actualUnit = testVec.unitVec();
    try testing.expect(math.approxEqRel(VT, expectedUnit.x, actualUnit.x, 0.00001));
    try testing.expect(math.approxEqRel(VT, expectedUnit.y, actualUnit.y, 0.00001));
    try testing.expect(math.approxEqRel(VT, expectedUnit.z, actualUnit.z, 0.00001));
}

test "Vec scalar" {
    const testVecAdd = vf.init(0.0, 2.2, 1789);
    const expectedAdd = vf.init(1.0, 3.2, 1790);
    const actualAdd = testVecAdd.add(1.0);
    try testing.expectEqual(expectedAdd, actualAdd);

    const testVecSub = vf.init(7.8, -0.8, 0.00003);
    const expectedSub = vf.init(6.6, -2, -1.19997);
    const actualSub = testVecSub.sub(1.2);

    try testing.expect(math.approxEqRel(VT, expectedSub.x, actualSub.x, 0.05));
    try testing.expect(math.approxEqRel(VT, expectedSub.y, actualSub.y, 0.05));
    try testing.expect(math.approxEqRel(VT, expectedSub.z, actualSub.z, 0.05));
}

test "Vec add subtract" {
    const testVecAdd = vf.init(0.0, 2.2, 1789);
    const expectedAdd = vf.init(5.2, 2.2, -2786);
    const actualAdd = testVecAdd.addVec(vf.init(5.2, 0.0, -4575));
    try testing.expectEqual(expectedAdd, actualAdd);

    const testVecSub = vf.init(7.8, -0.8, 0.00003);
    const expectedSub = vf.init(-376.2, -0.80001, -543.49997);
    const actualSub = testVecSub.subVec(vf.init(384, 0.00001, 543.5));
    try testing.expectEqual(expectedSub, actualSub);
}

test "Vec multiply divide" {
    const testVecMult = vf.init(13.4, -45.4, 34);
    const expectedMult = vf.init(30.82, -104.65, 78.2);
    const actualMult = testVecMult.multiply(2.3);
    try testing.expect(math.approxEqRel(VT, expectedMult.x, actualMult.x, 0.005));
    try testing.expect(math.approxEqRel(VT, expectedMult.y, actualMult.y, 0.005));
    try testing.expect(math.approxEqRel(VT, expectedMult.z, actualMult.z, 0.005));

    const testVecDiv = vf.init(-19.3, 89.4, 1.0);
    const expectedDiv = vf.init(2.608, -12.081, -0.135);
    const actualDiv = testVecDiv.divide(-7.4);
    try testing.expect(math.approxEqRel(VT, expectedDiv.x, actualDiv.x, 0.005));
    try testing.expect(math.approxEqRel(VT, expectedDiv.y, actualDiv.y, 0.005));
    try testing.expect(math.approxEqRel(VT, expectedDiv.z, actualDiv.z, 0.005));
}

test "Vec dot cross" {
    const testVecDotA = vf.init(6.4, -0.0704, 5);
    const testVecDotB = vf.init(-1.92, 85, 43);
    const expectedDot = 196.728;
    const actualDot = testVecDotA.dot(testVecDotB);
    try testing.expectEqual(expectedDot, actualDot);

    const testVecCrossA = vf.init(1.65, 3.9, -0.5);
    const testVecCrossB = vf.init(8.7, 4.3, 5.2);
    const expectedCross = vf.init(22.43, -12.93, -26.835);
    const actualCross = testVecCrossA.cross(testVecCrossB);
    try testing.expectEqual(expectedCross, actualCross);
}

test "Vec distance" {
    const testVecA = vf.init(1, 1, 0);
    const testVecB = vf.init(2, 1, 2);
    const expectedDist = 2.24;
    const actualDist = testVecA.distance(testVecB);
    try testing.expectEqual(expectedDist, actualDist);
}
