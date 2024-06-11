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
    fuzz: fsize,

    pub fn init(albedo: Vec, fuzz: fsize) Metal {
        const fuzzClamp = if (fuzz < 1.0) fuzz else 1.0;
        return .{ .albedo = albedo, .fuzz = fuzzClamp };
    }

    pub fn scatter(self: *const Metal, ray: Ray, hitRecord: HitRecord) ?Scatter {
        var reflected = ray.direction.reflect(hitRecord.normal);
        reflected = reflected.unitVec().addVec(Vec.randomUnitVector().multiply(self.fuzz));

        const hr = Scatter{
            .scattered = Ray.init(hitRecord.pos, reflected),
            .attenuation = self.albedo,
        };

        if (hr.scattered.direction.dot(hitRecord.normal) > 0) {
            return hr;
        } else {
            return null;
        }
    }
};

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////
