const std = @import("std");

const types = @import("types.zig");
const fsize = types.fsize;

pub fn degreesToRadians(degrees: fsize) fsize {
    return degrees * std.math.pi / 180.0;
}

// pub fn randomFloat() fsize {
//     const State = struct {
//         var seed: ?u64 = null;
//         var prng: std.rand.DefaultPrng = undefined;
//         var rand: std.rand.Random = undefined;
//
//         fn init() void {
//             seed = @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())));
//             prng = std.rand.DefaultPrng.init(seed.?);
//             rand = prng.random();
//         }
//     };
//     if (State.seed == null) State.init();
//
//     return State.rand.float(fsize);
// }

var prng: std.rand.DefaultPrng = std.rand.DefaultPrng.init(0);
const rand: std.rand.Random = prng.random();

pub fn randomFloat() fsize {
    return rand.float(fsize);
}

pub fn randomFloatRange(min: fsize, max: fsize) fsize {
    return min + (max - min) * randomFloat();
}
