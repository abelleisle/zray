const std = @import("std");
const math = std.math;

const types = @import("types.zig");
const Ray = types.Ray;
const Vec = types.Vec3f;
const fsize = types.fsize;
const HitRecord = types.HitRecord;
const Interval = types.Interval;

////////////////////////////////////////////////
//                    TYPE                    //
////////////////////////////////////////////////

pub const Scatter = struct {
    attenuation: Vec,
    scattered: Ray,
};

pub const Material = union(enum) {
    Lambertain: Lambertain,
    Metal: Metal,

    pub fn scatter(self: Material, ray: Ray, hitRecord: HitRecord) ?Scatter {
        return switch (self) {
            .Lambertain => |l| l.scatter(ray, hitRecord),
            .Metal => |m| m.scatter(ray, hitRecord),
        };
    }
};

pub const Lambertain = struct {
    albedo: Vec,

    pub fn init(albedo: Vec) Lambertain {
        return .{ .albedo = albedo };
    }

    pub fn scatter(self: *const Lambertain, ray: Ray, hitRecord: HitRecord) ?Scatter {
        _ = ray;
        var scatterDir = hitRecord.normal.addVec(Vec.randomUnitVector());

        // Catch degenerate scattering directions
        if (scatterDir.nearZero()) {
            scatterDir = hitRecord.normal;
        }

        return .{
            .scattered = Ray.init(hitRecord.pos, scatterDir),
            .attenuation = self.albedo,
        };
    }
};

pub const Metal = struct {
    albedo: Vec,

    pub fn init(albedo: Vec) Metal {
        return .{ .albedo = albedo };
    }

    pub fn scatter(self: *const Metal, ray: Ray, hitRecord: HitRecord) ?Scatter {
        const reflected = ray.direction.reflect(hitRecord.normal);

        return .{
            .scattered = Ray.init(hitRecord.pos, reflected),
            .attenuation = self.albedo,
        };
    }
};

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////
