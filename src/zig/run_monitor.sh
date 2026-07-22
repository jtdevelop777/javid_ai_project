#!/bin/bash
# สคริปต์รัน ZMQ Queue Monitor ด้วย Zig

echo "🔍 Checking port 5555 for Mojo/ZMQ Core..."
if ! nc -z 192.168.4.9 5555 2>/dev/null; then
    echo "⚠️ Warning: Port 5555 is not active yet."
else
    echo "✅ Port 5555 is active and reachable."
fi

echo "🚀 Compiling and running ZMQ Monitor..."
zig run zmq_monitor.zig