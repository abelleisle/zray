const std = @import("std");
const math = std.math;

/////////////////////////////////////////////////
//                    TYPES                    //
/////////////////////////////////////////////////

pub fn interval(T: type) type {
    const infinity = math.inf(T);
    return struct {
        const Interval = @This();

        min: T = infinity,
        max: T = -infinity,

        pub const empty = init(infinity, -infinity);
        pub const universe = init(-infinity, infinity);

        pub fn init(min: T, max: T) Interval {
            return .{
                .min = min,
                .max = max,
            };
        }

        pub fn size(self: *const Interval) T {
            return self.max - self.min;
        }

        pub fn contains(self: *const Interval, x: T) bool {
            return (self.min <= x) and (x <= self.max);
        }

        pub fn surrounds(self: *const Interval, x: T) bool {
            return (self.min < x) and (x < self.max);
        }

        pub fn clamp(self: *const Interval, x: T) T {
            if (x < self.min) return self.min;
            if (x > self.max) return self.max;
            return x;
        }
    };
}

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////
