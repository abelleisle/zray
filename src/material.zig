const std = @import("std");
const math = std.math;

const utils = @import("utils.zig");

const types = @import("types.zig");
const Ray = types.Ray;
const Vec3f = types.Vec3f;
const fsize = types.fsize;
const HitRecord = types.HitRecord;
const Interval = types.Interval;

////////////////////////////////////////////////
//                    TYPE                    //
////////////////////////////////////////////////

pub const Scatter = struct {
    attenuation: Vec3f.Type,
    scattered: Ray,
};

pub const Material = union(enum) {
    Lambertain: Lambertain,
    Metal: Metal,
    Dielectric: Dielectric,

    pub fn scatter(self: Material, ray: Ray, hitRecord: HitRecord) ?Scatter {
        return switch (self) {
            .Lambertain => |l| l.scatter(ray, hitRecord),
            .Metal => |m| m.scatter(ray, hitRecord),
            .Dielectric => |d| d.scatter(ray, hitRecord),
        };
    }
};

pub const Lambertain = struct {
    albedo: Vec3f.Type,

    pub fn init(albedo: Vec3f.Type) Lambertain {
        return .{ .albedo = albedo };
    }

    pub fn scatter(self: *const Lambertain, ray: Ray, hitRecord: HitRecord) ?Scatter {
        _ = ray;
        var scatterDir = hitRecord.normal + Vec3f.randomUnitVector();

        // Catch degenerate scattering directions
        if (Vec3f.nearZero(scatterDir)) {
            scatterDir = hitRecord.normal;
        }

        return .{
            .scattered = Ray.init(hitRecord.pos, scatterDir),
            .attenuation = self.albedo,
        };
    }
};

pub const Metal = struct {
    albedo: Vec3f.Type,
    fuzz: fsize,

    pub fn init(albedo: Vec3f.Type, fuzz: fsize) Metal {
        const fuzzClamp = if (fuzz < 1.0) fuzz else 1.0;
        return .{ .albedo = albedo, .fuzz = fuzzClamp };
    }

    pub fn scatter(self: *const Metal, ray: Ray, hitRecord: HitRecord) ?Scatter {
        var reflected = Vec3f.reflect(ray.direction, hitRecord.normal);
        reflected = Vec3f.unit(reflected) + (Vec3f.randomUnitVector() * Vec3f.S(self.fuzz));

        const hr = Scatter{
            .scattered = Ray.init(hitRecord.pos, reflected),
            .attenuation = self.albedo,
        };

        if (Vec3f.dot(hr.scattered.direction, hitRecord.normal) > 0) {
            return hr;
        } else {
            return null;
        }
    }
};

pub const Dielectric = struct {
    refractionIndex: fsize,

    pub fn init(refractionIndex: fsize) Dielectric {
        return .{ .refractionIndex = refractionIndex };
    }

    pub fn scatter(self: *const Dielectric, ray: Ray, hitRecord: HitRecord) ?Scatter {
        const ri = if (hitRecord.frontFace)
            1.0 / self.refractionIndex
        else
            self.refractionIndex;

        const unitDir = Vec3f.unit(ray.direction);

        const cosTheta = @min(Vec3f.dot(-unitDir, hitRecord.normal), 1.0);
        const sinTheta = math.sqrt(1.0 - (cosTheta * cosTheta));

        const cannotRefract = (ri * sinTheta) > 1.0;
        const direction = if (cannotRefract or (reflectance(cosTheta, ri) > utils.randomFloat()))
            Vec3f.reflect(unitDir, hitRecord.normal)
        else
            Vec3f.refract(unitDir, hitRecord.normal, ri);

        return Scatter{ .attenuation = Vec3f.Type{1, 1, 1}, .scattered = Ray.init(hitRecord.pos, direction) };
    }

    fn reflectance(cosine: fsize, refractionIndex: fsize) fsize {
        const r0 = math.pow(fsize, (1.0 - refractionIndex) / (1 + refractionIndex), 2);

        return r0 + (1 - r0) * math.pow(fsize, (1 - cosine), 5);
    }
};

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////
