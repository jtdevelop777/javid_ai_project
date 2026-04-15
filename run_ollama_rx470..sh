#!/bin/bash

# https://gemini.google.com/share/c87eba65d419

# --- การตั้งค่าสำหรับ GPU AMD RX 470 ---
export HSA_OVERRIDE_GFX_VERSION=8.0.3
export OLLAMA_VULKAN=1

# --- การตั้งค่าการจัดการโมเดล ---
export OLLAMA_NUM_PARALLEL=4
export OLLAMA_MAX_LOADED_MODELS=4

echo "กำลังเริ่ม Ollama สำหรับกัปตัน Jack..."
echo "จำกัดการใช้งาน CPU ไว้ที่ 6 Cores (0-5)"
echo "สถานะ GPU Override: GFX 8.0.3"

# รัน Ollama ด้วย taskset
taskset -c 0-5 ollama serve