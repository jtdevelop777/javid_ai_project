const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    _ = allocator;

    std.debug.print("🚀 Zig HTTP Worker starting up...\n", .{});

    const address = try std.net.Address.parseIp4("192.168.4.9", 8001);
    var stream = try std.net.tcpConnectToAddress(address);
    defer stream.close();

    const body = "{\"command\": \"Hello from Zig HTTP Worker!\"}";
    
    // จัดรูปแบบ HTTP Request ให้ถูกต้องตามมาตรฐาน RFC
    var buf: [512]u8 = undefined;
    const request = try std.fmt.bufPrint(&buf, 
        "POST /task HTTP/1.1\r\n" ++
        "Host: 192.168.4.9:8001\r\n" ++
        "Content-Type: application/json\r\n" ++
        "Content-Length: {d}\r\n" ++
        "Connection: close\r\n" ++
        "\r\n" ++
        "{s}", 
        .{body.len, body}
    );

    try stream.writeAll(request);
    std.debug.print("📤 Sent HTTP POST to Mojo FastAPI successfully.\n", .{});

    var read_buffer: [4096]u8 = undefined;
    const bytes_read = try stream.read(&read_buffer);
    if (bytes_read > 0) {
        std.debug.print("📥 Response:\n{s}\n", .{read_buffer[0..bytes_read]});
    }
}