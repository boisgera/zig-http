const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
const ISS_NOW = "http://api.open-notify.org/iss-now.json";

// Source: https://zig.news/nameless/coming-soon-to-a-zig-near-you-http-client-5b81

const ISS = struct {
    message: []u8,
    timestamp: i64,
    iss_position: struct { longitude: f64, latitude: f64 },
};

pub fn main() !void {
    var client = std.http.Client{ .allocator = allocator };
    const uri = try std.Uri.parse(ISS_NOW);
    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();
    // try headers.append("accept", "*/*");
    var req = try client.open(.GET, uri, headers, .{});
    try req.send(.{});
    try req.wait();

    const content_type = req.response.headers.getFirstValue("content-type") orelse "text/plain";
    std.debug.print("content type: {s}\n", .{content_type});
    const body = req.reader().readAllAlloc(allocator, 8192) catch unreachable;
    std.debug.print("body: {s}\n", .{body});

    const data_wrapper = try std.json.parseFromSlice(ISS, allocator, body, .{});
    defer data_wrapper.deinit();

    std.debug.print("{}\n", .{@TypeOf(data_wrapper.value)});

    const iss = data_wrapper.value;
    std.debug.print("message: {s}\ntimestamp: {}\nposition: {}, {}\n", .{ iss.message, iss.timestamp, iss.iss_position.longitude, iss.iss_position.latitude });
}
