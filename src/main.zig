const std = @import("std");
const lib = @import("lib.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // const data_wrapper = try lib.issPosition(allocator);
    // defer data_wrapper.deinit();
    // const data = data_wrapper.value;
    // const iss_position = data.iss_position;
    // std.debug.print("{} {}\n", .{ iss_position.latitude, iss_position.longitude });

    try lib.annieAreYouOk(allocator);
}
