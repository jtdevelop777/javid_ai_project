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

* ## 🌟 Key Capabilities (ความสามารถหลักของระบบ)

*   **🎙️ Local Smart Video Cutting (AI ตัดต่อและคัดแยกเดดแอร์อัจฉริยะ):** ระบบสามารถวิเคราะห์เสียงและตัดช่วงเงียบ (Dead Air) ออกจากวิดีโอได้โดยอัตโนมัติผ่านคำสั่ง Local CLI โดยใช้ทรัพยากรเครื่องอย่างคุ้มค่า ไม่ต้องพึ่งพาคลาวด์ภายนอก
*   **🤖 Hybrid LLM Orchestrator (ตัวควบคุมและสั่งการโมเดลภายในเครื่อง):** ใช้ตัวรันภาษา Mojo ประสานงานร่วมกับ Ollama เพื่อแปลคำสั่งจากภาษาพูดของมนุษย์ ไปเป็นคำสั่งควบคุมซอฟต์แวร์และฮาร์ดแวร์โดยตรงแบบ Real-time
*   **🔌 Low-Level Hardware Control (การควบคุมฮาร์ดแวร์ระดับต่ำ):** สถาปัตยกรรมที่ออกแบบมาเพื่อเชื่อมต่อและควบคุมอุปกรณ์ประมวลผล (FPGA / GPU) ได้โดยตรง ด้วยการจัดการหน่วยความจำที่รวดเร็วและปลอดภัย (Safety First)
*   **⚡ High-Performance Mojo Native (ประมวลผลความเร็วสูง):** ใช้พลังของภาษา Mojo ในการจัดการ Worker Threads ทำให้การรับส่งข้อมูลและการประมวลผลพื้นฐาน (Data Pipelines) ทำงานได้เร็วใกล้เคียงกับ C/C++
