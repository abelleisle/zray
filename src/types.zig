const math = @import("std").math;

const Material = @import("material.zig").Material;

/////////////////////////////////////////////////
//                    TYPES                    //
/////////////////////////////////////////////////

// Float sizes
pub const fsize = f32;

// String
pub const String = @import("types/String.zig");

// Vectors
// const Vector3Base = @import("types/vec3.zig");
pub const Vec = @import("types/vecSIMD.zig");
pub const Vec3f = Vec.vecType(3, fsize);
pub const Vec3c = Vec.vecType(3, u8);

// Rays
pub const Ray = @import("types/Ray.zig").ray(Vec3f, fsize);

// Hittable
pub const HitRecord = struct {
    pos: Vec3f,
    normal: Vec3f,
    time: fsize,
    frontFace: bool,
    mat: Material,

    pub fn init(pos: Vec3f, time: fsize, ray: Ray, outwordNormal: Vec3f, mat: Material) HitRecord {
        const ff: bool = Vec.dot(ray.direction, outwordNormal) < 0;
        return .{ .pos = pos, .time = time, .frontFace = ff, .normal = if (ff) outwordNormal else -outwordNormal, .mat = mat };
    }
};

// Interval
pub const Interval = @import("types/interval.zig").interval(fsize);

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

test {
    @import("std").testing.refAllDecls(@This());
}
