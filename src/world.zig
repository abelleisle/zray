const std = @import("std");

const Allocator = std.mem.Allocator;

const shapes = @import("shapes.zig");
const Shape = shapes.Shape;

const Ray = @import("types.zig").Ray;
const Vec = @import("types.zig").Vec3f;
const fsize = @import("types.zig").fsize;
const HitRecord = @import("types.zig").HitRecord;

const ShapeList = std.ArrayList(Shape);

////////////////////////////////////////////////
//                    TYPE                    //
////////////////////////////////////////////////
pub const World = struct {
    allocator: Allocator,

    objects: ShapeList,

    /// Create a world object
    pub fn init(allocator: Allocator) World {
        return .{
            .allocator = allocator,
            .objects = ShapeList.init(allocator),
        };
    }

    /// Destroy a world object.
    /// Will destroy all owned shapes and free the pointer memory
    pub fn deinit(self: *World) void {
        for (self.objects.items) |s| {
            s.deinit();
        }
        self.objects.deinit();
    }

    /// Add a shape to the world
    /// This will cause the world to own the memory pointed to by the shape.
    pub fn add(self: *World, shape: Shape) !void {
        try self.objects.append(shape);
    }

    pub fn intersection(self: *const World, ray: Ray, rayTMin: fsize, rayTMax: fsize) ?HitRecord {
        var hr: ?HitRecord = null;
        var closestT = rayTMax;

        for (self.objects.items) |*o| {
            if (o.intersection(ray, rayTMin, closestT)) |hit| {
                closestT = hit.time;
                hr = hit;
            }
        }

        return hr;
    }
};

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

const testing = std.testing;
const talloc = testing.allocator;

test "World Creation and destruction" {
    var w = World.init(talloc);
    defer w.deinit();

    const sp = try shapes.Sphere.init(talloc, Vec.init(0, 0, -1), 0.5);
    try w.add(sp.shape);
}
