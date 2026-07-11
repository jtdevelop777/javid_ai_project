# ⚡ javid_ai_project 

> **ระบบ AI อัจฉริยะ (Javid) สำหรับจัดการเครื่องมือ ควบคุม Hardware และประมวลผลวิดีโอแบบ Local 100%**

โปรเจกต์นี้ถูกพัฒนาขึ้นภายใต้แนวคิด **"Simple First"** เพื่อรีดประสิทธิภาพฮาร์ดแวร์ระดับขีดสุด โดยไม่ต้องพึ่งพาบริการ Cloud ราคาแพงและไม่ต้องเชื่อมต่ออินเทอร์เน็ต!

## 🚀 Tech Stack & Architecture
* **Core Language:** Mojo (Native Core & High-Speed Worker) เพื่อการจัดการ Memory และ Thread ระดับเดียวกับ C/C++
* **Local AI Orchestrator:** Ollama (`deepseek-coder` / `llama3`) รันบน GPU Local
* **Automation Tools:** Auto-Editor & FFmpeg ประมวลผลและตัดเดดแอร์วิดีโออัตโนมัติผ่าน Linux CLI 
* **Communication Stack:** FastAPI (Inline Python integration via Mojo) + ZeroMQ (ZMQ) สำหรับรับส่ง Task Payload

## 💻 Hardware Testing Environment
ระบบนี้ถูกทดสอบและปรับแต่งให้ทำงานได้อย่างลื่นไหลบน private hardware ในแล็บของเรา:
* CPU: AMD FX-8100 
* GPU: AMD Radeon RX 470 (Configured via Vulkan/ROCm)
