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
pub const Ray = @import("types/Ray.zig").ray(Vec3f, isize);

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

test {
    @import("std").testing.refAllDecls(@This());
}
