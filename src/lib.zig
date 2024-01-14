const std = @import("std");
const json = std.json;

const ISS_NOW = "http://api.open-notify.org/iss-now.json";
const OLLAMA = "http://localhost:11434/api/generate";

// Source: https://zig.news/nameless/coming-soon-to-a-zig-near-you-http-client-5b81

const ISS = struct {
    message: []u8,
    timestamp: i64,
    iss_position: struct { longitude: f64, latitude: f64 },
};

pub fn issPosition(allocator: std.mem.Allocator) !json.Parsed(ISS) {
    var client = std.http.Client{ .allocator = allocator };
    const uri = try std.Uri.parse(ISS_NOW);
    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();
    try headers.append("accept", "*/*");
    var req = try client.open(.GET, uri, headers, .{});
    try req.send(.{});
    try req.wait();

    const content_type = req.response.headers.getFirstValue("content-type") orelse "text/plain";
    _ = content_type;
    //std.debug.print("content type: {s}\n", .{content_type});
    const body = req.reader().readAllAlloc(allocator, 8192) catch unreachable;
    //std.debug.print("body: {s}\n", .{body});

    const data_wrapper = try std.json.parseFromSlice(ISS, allocator, body, .{});

    // std.debug.print("{}\n", .{@TypeOf(data_wrapper)});
    return data_wrapper;
}

const request_body =
    \\{
    \\  "model": "mistral", 
    \\  "prompt": "Tell me the story of Neo"}
    \\}
;

pub fn annieAreYouOk(allocator: std.mem.Allocator) !void {
    var client = std.http.Client{ .allocator = allocator };
    const uri = try std.Uri.parse(OLLAMA);
    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();
    try headers.append("accept", "*/*");
    var request = try client.open(.POST, uri, headers, .{});
    request.transfer_encoding = .chunked;
    try request.send(.{});
    try request.writer().writeAll(request_body);
    try request.finish();
    try request.wait();
    const status = request.response.status;
    std.debug.print("status: {} ({})\n", .{ status, @intFromEnum(status) });
    const content_type = request.response.headers.getFirstValue("content-type") orelse "text/plain";
    std.debug.print("content type: {s}\n", .{content_type});

    const stdout = std.io.getStdOut().writer();
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    const buffer_writer = buffer.writer();
    var reader = request.reader();
    while (reader.streamUntilDelimiter(buffer_writer, '\n', null)) |_| {
        defer buffer.clearAndFree();
        // std.debug.print("{s}\n", .{buffer.items});
        const parsed_value = try std.json.parseFromSlice(std.json.Value, allocator, buffer.items, .{});
        defer parsed_value.deinit();
        // std.debug.print("* {}\n", .{parsed_value});
        const object = parsed_value.value.object;
        const done = object.get("done").?.bool;
        if (done) {
            break;
        }
        const response = object.get("response").?.string;
        try stdout.print("{s}", .{response});
    } else |err| {
        try std.testing.expect(err == error.EndOfStream);
    }
    std.debug.print("{s}\n", .{buffer.items});
}
