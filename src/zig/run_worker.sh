#!/bin/bash

echo "🔍 Checking port 555ุุ6..."
PID=$(lsof -t -i:5556)

if [ -n "$PID" ]; then
    echo "⚠️ Found process using port 5556 (PID: $PID). Killing it..."
    kill -9 $PID
    sleep 1
    echo "✅ Port 5556 is now free."
else
    echo "✅ Port 5556 is already free."
fi

echo "🚀 Starting Zig Native TCP Server..."
zig run zmq_worker.zig