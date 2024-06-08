/////////////////////////////////////////////////
//                    TYPES                    //
/////////////////////////////////////////////////

// String
pub const String = @import("types/String.zig");

// Vectors
const Vector3Base = @import("types/vec3.zig");
pub const Vec3f = Vector3Base.vec3(f32);
pub const Vec3i = Vector3Base.vec3(isize);

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

test {
    @import("std").testing.refAllDecls(@This());
}
