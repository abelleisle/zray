const std = @import("std");
const Allocator = std.mem.Allocator;

const fs = std.fs;

const PPM = @import("image/ppm.zig");

const Vec3 = @import("types.zig").Vec3;

/////////////////////////////////////////////////////
//                    FUNCTIONS                    //
/////////////////////////////////////////////////////

pub fn main() !void {
    var arenaAlloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAlloc.deinit();

    const alloc = arenaAlloc.allocator();

    var ppm = try PPM.init(alloc, 255, 255);
    defer ppm.deinit();

    try ppm.fillDemo();

    var file = try ppm.render();
    defer file.deinit();

    var fsf = try fs.createFileAbsolute("/tmp/demo.ppm", .{});
    defer fsf.close();

    const writtenLen = try fsf.write(file.str());
    if (writtenLen != file.len) {
        return error.WriteSize;
    }
}

///////////////////////////////////////////////////
//                    TESTING                    //
///////////////////////////////////////////////////

test {
    @import("std").testing.refAllDecls(@This());
}
