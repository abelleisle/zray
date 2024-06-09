const math = @import("std").math;
/////////////////////////////////////////////////
//                    TYPES                    //
/////////////////////////////////////////////////

// Float sizes
pub const fsize = f32;

// String
pub const String = @import("types/String.zig");

// Vectors
const Vector3Base = @import("types/vec3.zig");
pub const Vec3f = Vector3Base.vec3(fsize);
pub const Vec3i = Vector3Base.vec3(isize);
pub const Vec3c = Vector3Base.vec3(u8);

// Rays
pub const Ray = @import("types/Ray.zig").ray(Vec3f, fsize);

// Hittable
pub const HitRecord = struct {
    pos: Vec3f,
    normal: Vec3f,
    time: fsize,
    frontFace: bool,

    pub fn init(pos: Vec3f, time: fsize, ray: Ray, outwordNormal: Vec3f) HitRecord {
        const ff: bool = ray.direction.dot(outwordNormal) < 0;
        return .{ .pos = pos, .time = time, .frontFace = ff, .normal = if (ff) outwordNormal else outwordNormal.negate() };
    }
};

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

test {
    @import("std").testing.refAllDecls(@This());
}
