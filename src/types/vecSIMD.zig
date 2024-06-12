const std = @import("std");
const math = std.math;

const utils = @import("../utils.zig");

////////////////////////////////////////////////
//                    TYPE                    //
////////////////////////////////////////////////

const fsize = f32;

///////////////
// Init

pub fn vecType(comptime len: comptime_int, comptime T: type) type {
    return @Vector(len, T);
}

pub inline fn vec3(comptime T: type, x: T, y: T, z: T) vecType(3, T) {
    if (@TypeOf(x) != @TypeOf(y) and @TypeOf(y) != @TypeOf(z)) {
        @compileError("x, y, and z must be the same type");
    }
    return @Vector(3, T){ x, y, z };
}

pub inline fn vec3f(x: fsize, y: fsize, z: fsize) vecType(3, fsize) {
    return vec3(fsize, x, y, z);
}

pub inline fn scalar(comptime T: type, value: anytype) T {
    _ = checkType(T);
    return @splat(value);
}

///////////////
// Checks

inline fn checkType(comptime T: type) type {
    if (@typeInfo(T) != .Vector) {
        @compileError("Can only pass vectors into this function");
    }
    return T;
}

inline fn vSize(comptime T: type) comptime_int {
    _ = checkType(T);
    return @typeInfo(T).Vector.len;
}

inline fn vType(comptime T: type) type {
    _ = checkType(T);
    return @typeInfo(T).Vector.child;
}

///////////////
// Random

pub inline fn random(comptime T: type) T {
    _ = checkType(T);
    const channels = vSize(T);
    const vtype = vType(T);
    var tmp = scalar(T, 0);
    for (0..channels) |c| {
        tmp[c] = utils.random(vtype);
    }
    return tmp;
}

pub inline fn randomRange(comptime T: type, min: anytype, max: anytype) T {
    _ = checkType(T);
    const channels = vSize(T);
    const vtype = vType(T);
    var tmp = scalar(T, 0);
    for (0..channels) |c| {
        tmp[c] = utils.randomRange(vtype, min, max);
    }
    return tmp;
}

pub inline fn randomUnitSphere(comptime T: type) T {
    while (true) {
        const v = randomRange(T, -1, 1);
        if (lengthSq(v) < 1) return v;
    }
}

pub inline fn randomUnitVector(comptime T: type) T {
    return unit(randomUnitSphere(T));
}

pub inline fn randomUnitDisk(comptime T: type) T {
    _ = checkType(T);
    const channels = vSize(T);
    const subtype = vType(T);
    while (true) {
        var tmp = scalar(T, 0);
        for (0..channels - 1) |c| {
            tmp[c] = utils.randomRange(subtype, -1, 1);
        }
        // const d = Vec.init(utils.randomFloatRange(-1, 1), utils.randomFloatRange(-1, 1), 0);
        if (lengthSq(tmp) < 1) return tmp;
    }
}

pub inline fn randomHemisphere(normal: anytype) @TypeOf(normal) {
    const T = checkType(@TypeOf(normal));
    const v = randomUnitVector(T);
    return if (dot(v, normal) > 0.0) v else -v;
}

///////////////
// Functions

pub inline fn length(v: anytype) vType(@TypeOf(v)) {
    _ = checkType(@TypeOf(v));
    return math.sqrt(lengthSq(v));
}

pub inline fn lengthSq(v: anytype) vType(@TypeOf(v)) {
    return dot(v, v);
}

pub inline fn dot(lhs: anytype, rhs: anytype) vType(@TypeOf(lhs)) {
    const lt = checkType(@TypeOf(lhs));
    const rt = checkType(@TypeOf(rhs));
    if (lt != rt) {
        @compileError("Only vectors of the same type can be used");
    }

    return @reduce(.Add, lhs * rhs);
}

pub fn unit(v: anytype) @TypeOf(v) {
    return v / scalar(@TypeOf(v), length(v));
}

pub inline fn cross(lhs: anytype, rhs: anytype) @TypeOf(lhs) {
    const lt = checkType(@TypeOf(lhs));
    const rt = checkType(@TypeOf(rhs));
    if (lt != rt) {
        @compileError("Only vectors of the same type can be used");
    }

    return switch (vSize(lt)) {
        3 => lt{
            lhs[1] * rhs[2] - lhs[2] * rhs[1],
            lhs[2] * rhs[0] - lhs[0] * rhs[2],
            lhs[0] * rhs[1] - lhs[1] * rhs[0],
        },
        else => @compileError("Cross product not implemented for that size vector"),
    };
}

pub inline fn distance(lhs: anytype, rhs: anytype) vType(@TypeOf(lhs)) {
    const lt = checkType(@TypeOf(lhs));
    const rt = checkType(@TypeOf(rhs));
    if (lt != rt) {
        @compileError("Only vectors of the same type can be used");
    }

    return length(rhs - lhs);
}

pub inline fn reflect(v: anytype, normal: anytype) @TypeOf(v) {
    const vt = checkType(@TypeOf(v));
    const nt = checkType(@TypeOf(normal));
    if (vt != nt) {
        @compileError("Only vectors of the same type can be used");
    }

    return v - scalar(vt, 2 * dot(v, normal)) * normal;
}

pub inline fn refract(uv: anytype, normal: anytype, etaiOverEtat: anytype) @TypeOf(uv) {
    const uvt = checkType(@TypeOf(uv));
    const nt = checkType(@TypeOf(normal));
    if (uvt != nt) {
        @compileError("Only vectors of the same type can be used");
    }
    const etat = @TypeOf(etaiOverEtat);
    const uvts = vType(uvt);
    if (etat != uvts) {
        @compileError("eta and sub-type of uv must be the same");
    }

    const cosTheta = @min(dot(-uv, normal), 1.0);
    const rOutPerp = scalar(uvt, etaiOverEtat) * (uv + (scalar(uvt, cosTheta) * normal));
    const rOutParallel = normal * scalar(uvt, -math.sqrt(@abs(1.0 - lengthSq(rOutPerp))));

    return rOutPerp + rOutParallel;
}

pub inline fn nearZero(v: anytype) bool {
    const T = checkType(@TypeOf(v));
    const vsT = vType(T);
    // const vsS = vSize(T);

    const tolerance = scalar(T, math.floatEps(vsT));

    return @reduce(.And, @abs(v) < tolerance);

    // for (0..vsS) |c| {
    //     if (!math.approxEqAbs(vsT, v[c], 0, tolerance)) return false;
    // }

    // return true;
}

// pub fn format(self: Vec, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
//     _ = fmt;
//     _ = options;
//
//     try writer.print("({d}, {d}, {d})", .{ self.x, self.y, self.z });
// }

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

// const testing = std.testing;
//
// const vf = vec3(f32);
// const VT = f32;
//
// test "Vec init" {
//     const testVec = vf.init(4.6, -9.5, 0.1);
//     const expected = .{ .x = 4.6, .y = -9.5, .z = 0.1 };
//     try testing.expectEqual(expected.x, testVec.x);
//     try testing.expectEqual(expected.y, testVec.y);
//     try testing.expectEqual(expected.z, testVec.z);
// }
//
// test "Vec negate" {
//     const testVec = vf.init(-23424.2, 75.2, 128482.8);
//     const expected = vf.init(23424.2, -75.2, -128482.8);
//     const actual = testVec.negate();
//     try testing.expectEqual(expected, actual);
// }
//
// test "Vec length" {
//     const testVec = vf.init(3.5, 24.0, -1.0);
//     const expected: VT = 24.27447;
//     const actual: VT = testVec.length();
//     try testing.expect(math.approxEqRel(VT, expected, actual, 0.0000001));
//
//     const expectedUnit = vf.init(0.144184, 0.988693, -0.0411955);
//     const actualUnit = testVec.unitVec();
//     try testing.expect(math.approxEqRel(VT, expectedUnit.x, actualUnit.x, 0.00001));
//     try testing.expect(math.approxEqRel(VT, expectedUnit.y, actualUnit.y, 0.00001));
//     try testing.expect(math.approxEqRel(VT, expectedUnit.z, actualUnit.z, 0.00001));
// }
//
// test "Vec scalar" {
//     const testVecAdd = vf.init(0.0, 2.2, 1789);
//     const expectedAdd = vf.init(1.0, 3.2, 1790);
//     const actualAdd = testVecAdd.add(1.0);
//     try testing.expectEqual(expectedAdd, actualAdd);
//
//     const testVecSub = vf.init(7.8, -0.8, 0.00003);
//     const expectedSub = vf.init(6.6, -2, -1.19997);
//     const actualSub = testVecSub.sub(1.2);
//
//     try testing.expect(math.approxEqRel(VT, expectedSub.x, actualSub.x, 0.05));
//     try testing.expect(math.approxEqRel(VT, expectedSub.y, actualSub.y, 0.05));
//     try testing.expect(math.approxEqRel(VT, expectedSub.z, actualSub.z, 0.05));
// }
//
// test "Vec add subtract" {
//     const testVecAdd = vf.init(0.0, 2.2, 1789);
//     const expectedAdd = vf.init(5.2, 2.2, -2786);
//     const actualAdd = testVecAdd.addVec(vf.init(5.2, 0.0, -4575));
//     try testing.expectEqual(expectedAdd, actualAdd);
//
//     const testVecSub = vf.init(7.8, -0.8, 0.00003);
//     const expectedSub = vf.init(-376.2, -0.80001, -543.49997);
//     const actualSub = testVecSub.subVec(vf.init(384, 0.00001, 543.5));
//     try testing.expectEqual(expectedSub, actualSub);
// }
//
// test "Vec multiply divide" {
//     const testVecMult = vf.init(13.4, -45.4, 34);
//     const expectedMult = vf.init(30.82, -104.65, 78.2);
//     const actualMult = testVecMult.multiply(2.3);
//     try testing.expect(math.approxEqRel(VT, expectedMult.x, actualMult.x, 0.005));
//     try testing.expect(math.approxEqRel(VT, expectedMult.y, actualMult.y, 0.005));
//     try testing.expect(math.approxEqRel(VT, expectedMult.z, actualMult.z, 0.005));
//
//     const testVecDiv = vf.init(-19.3, 89.4, 1.0);
//     const expectedDiv = vf.init(2.608, -12.081, -0.135);
//     const actualDiv = testVecDiv.divide(-7.4);
//     try testing.expect(math.approxEqRel(VT, expectedDiv.x, actualDiv.x, 0.005));
//     try testing.expect(math.approxEqRel(VT, expectedDiv.y, actualDiv.y, 0.005));
//     try testing.expect(math.approxEqRel(VT, expectedDiv.z, actualDiv.z, 0.005));
// }
//
// test "Vec dot cross" {
//     const testVecDotA = vf.init(6.4, -0.0704, 5);
//     const testVecDotB = vf.init(-1.92, 85, 43);
//     const expectedDot = 196.728;
//     const actualDot = testVecDotA.dot(testVecDotB);
//     try testing.expectEqual(expectedDot, actualDot);
//
//     const testVecCrossA = vf.init(1.65, 3.9, -0.5);
//     const testVecCrossB = vf.init(8.7, 4.3, 5.2);
//     const expectedCross = vf.init(22.43, -12.93, -26.835);
//     const actualCross = testVecCrossA.cross(testVecCrossB);
//     try testing.expectEqual(expectedCross, actualCross);
// }
//
// test "Vec distance" {
//     const testVecA = vf.init(1, 1, 0);
//     const testVecB = vf.init(2, 1, 2);
//     const expectedDist = 2.24;
//     const actualDist = testVecA.distance(testVecB);
//     try testing.expectEqual(expectedDist, actualDist);
// }
