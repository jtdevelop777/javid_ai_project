#!/bin/bash

echo "🛑 [Javid Orchestrator] Stopping existing Mojo processes..."
# ปิด process ที่รันผ่าน pixi หรือ uvicorn ค้างไว้
pkill -f main.mojo
pkill -f uvicorn

echo "✅ All processes cleared."

# รอ 1 วินาทีให้ระบบเคลียร์ไฟล์ Lock
sleep 1

echo "🚀 Starting Javid AI System via Pixi..."
# เปลี่ยนจาก mojo main.mojo เป็น pixi run แบบนี้ครับ
cd /mnt/javid_data/projects/javid_ai/src/mojo/mojoworker
pixi run mojo main.mojo  # (หรือคำสั่งรันระบบที่คุณใช้)
