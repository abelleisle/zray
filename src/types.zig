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
const VectorBase = @import("types/vecSIMD.zig");
pub const Vec3f = VectorBase.vecType(3, fsize);
pub const Vec3c = VectorBase.vecType(3, u8);

pub fn vec3(x: fsize, y: fsize, z: fsize) Vec3f.Type {
    return Vec3f.Type{ x, y, z };
}

// Rays
pub const Ray = @import("types/Ray.zig").ray(Vec3f, fsize);

// Hittable
pub const HitRecord = struct {
    pos: Vec3f.Type,
    normal: Vec3f.Type,
    time: fsize,
    frontFace: bool,
    mat: Material,

    pub fn init(pos: Vec3f.Type, time: fsize, ray: Ray, outwordNormal: Vec3f.Type, mat: Material) HitRecord {
        const ff: bool = Vec3f.dot(ray.direction, outwordNormal) < 0;
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
