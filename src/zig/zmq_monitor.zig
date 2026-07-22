const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    _ = allocator;

    std.debug.print("🔄 [Zig ZMQ Continuous Monitor] Starting real-time polling (Press Ctrl+C to stop)...\n\n", .{});

    while (true) {
        const address = std.net.Address.parseIp4("192.168.4.9", 8001) catch |err| {
            std.debug.print("❌ Failed to parse IP: {}\n", .{err});
            std.time.sleep(1 * std.time.ns_per_s);
            continue;
        };

        var stream = std.net.tcpConnectToAddress(address) catch {
            std.debug.print("⏳ Waiting for Mojo/FastAPI server to respond...\r", .{});
            std.time.sleep(1 * std.time.ns_per_s);
            continue;
        };

        const request =
            "GET /queue/status HTTP/1.1\r\n" ++
            "Host: 192.168.4.9:8001\r\n" ++
            "Connection: close\r\n" ++
            "\r\n";

        stream.writeAll(request) catch {
            stream.close();
            std.time.sleep(1 * std.time.ns_per_s);
            continue;
        };

        var read_buffer: [4096]u8 = undefined;
        const bytes_read = stream.read(&read_buffer) catch 0;
        stream.close();

        if (bytes_read > 0) {
            const response = read_buffer[0..bytes_read];
            if (std.mem.indexOf(u8, response, "\r\n\r\n")) |idx| {
                const json_body = response[idx + 4 ..];
                std.debug.print("📊 [Status Update] {s}\n", .{json_body});
            } else {
                std.debug.print("📊 [Raw Response] {s}\n", .{response});
            }
        } else {
            std.debug.print("ℹ️ No response received.\n", .{});
        }

        std.time.sleep(1 * std.time.ns_per_s);
    }
}
