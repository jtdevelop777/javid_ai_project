#!/bin/bash
echo "--- Javid AI System Health Check ---"
# เช็ค Ollama (Port 11434)
netstat -tuln | grep 11434 && echo "✅ Ollama: Online" || echo "❌ Ollama: Offline"
# เช็ค ZeroMQ Backend (Port 5555)
netstat -tuln | grep 5555 && echo "✅ Backend (ZMQ): Online" || echo "❌ Backend (ZMQ): Offline"
# เช็ค Docker Database (Port 8000)
docker ps | grep javid_db && echo "✅ Database: Online" || echo "❌ Database: Offline"
