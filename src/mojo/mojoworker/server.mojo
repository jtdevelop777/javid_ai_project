from std.python import Python


def main() raises:
    var zmq = Python.import_module("zmq")
    var requests = Python.import_module("requests")

    var context = zmq.Context()
    var receiver = context.socket(zmq.PULL)
    receiver.bind("tcp://*:5555")

    var publisher = context.socket(zmq.PUB)
    publisher.bind("tcp://*:8002")

    print("------------------------------------------")
    print("🚀 Javid MQ System: Flow Testing [Active]")
    print("------------------------------------------")

    while True:
        # --- RECEIVE: รับงาน ---
        var msg = receiver.recv_string()
        var message = String(msg)
        print("📩 กัปตันสั่งมาว่า:", message)

        # 1. LOG IMMEDIATELY: บันทึกลง DB ทันทีสถานะ PENDING
        log_to_sqlite(message, "PENDING", "-")

        # 2. ESTIMATION: ส่งเวลาประเมินให้ Client ทันที
        var est_wait = 5.0 + (Float64(message.byte_length()) / 10.0)
        publisher.send_string(
            '{"type": "estimation", "value": ' + String(est_wait) + "}"
        )

        # 3. INTENT CLASSIFICATION: แยกประเภทคำสั่ง
        if "พักผ่อน" in message:
            # --- กระบวนการพักผ่อน (สรุปงาน/ปิดประชุม) ---
            var summary = (
                "สรุปภารกิจวันนี้: ติดตั้งระบบ MQ สำเร็จ บันทึก Baseline ลง Git"
                " เรียบร้อย"
            )
            publisher.send_string(
                '{"type": "answer", "value": "' + summary + '"}'
            )
            log_to_sqlite(message, "COMPLETED", summary)
            print("💤 รับทราบครับกัปตัน พักผ่อนได้!")
            # ตรงนี้กัปตันอาจจะใส่ break หรือคำสั่งปิดระบบอื่นๆ ได้

        else:
            # --- ส่งให้ AI ประมวลผล ---
            print("🤖 กำลังถาม Ollama...")
            var ai_reply = ask_ollama(message)

            # 4. SAVE KNOW-HOW: บันทึกผลลัพธ์ลง DB
            log_to_sqlite(message, "COMPLETED", ai_reply)

            # 5. PUBLISH: ส่งคำตอบกลับทาง PUB 8002
            var ai_reply_safe = (
                ai_reply.replace('"', '\\"')
                .replace("\n", "\\n")
                .replace("\r", "\\r")
            )
            publisher.send_string(
                '{"type": "answer", "value": "' + ai_reply_safe + '"}'
            )
            print("✨ ภารกิจสำเร็จ บันทึก Know-how เรียบร้อย")


def ask_ollama_cli(prompt: String) -> String:
    try:
        var subprocess = Python.import_module("subprocess")

        # สร้าง Python List แทน List ของ Mojo เพื่อให้ส่งเข้า subprocess ได้ถูกต้อง
        var cmd = Python.list()
        cmd.append("ollama")
        cmd.append("run")
        cmd.append("qwen2")
        cmd.append(prompt)

        var result = subprocess.run(
            cmd, capture_output=True, text=True, encoding="utf-8", timeout=60
        )

        if result.returncode == 0:
            return String(String(result.stdout).strip())
        else:
            return "CLI Error: " + String(String(result.stderr).strip())

    except e:
        return "Execution Error: " + String(e)


# --- ฟังก์ชันช่วย (Helpers) ---


def ask_ollama(prompt: String) -> String:
    try:
        var requests = Python.import_module("requests")
        var url = "http://192.168.4.9:11434/api/generate"
        var payload = Python.dict()
        # payload["model"] = "llama3"
        # payload["model"] = "qwen2"
        # payload["model"] = "dimavz/whisper-tiny"
        payload["model"] = "qwen2"
        payload["prompt"] = prompt
        payload["stream"] = False

        var response = requests.post(url, json=payload, timeout=10)
        var res_json = response.json()
        var text = String(res_json["response"])
        print("DEBUG: AI ตอบว่า ->", text)  # <--- เพิ่มบรรทัดนี้ครับ
        return text
    except e:
        return "ERROR: เกิดข้อผิดพลาดในการเชื่อมต่อ"


def log_to_sqlite(cmd: String, status: String, response: String):
    try:
        var sqlite3 = Python.import_module("sqlite3")
        var conn = sqlite3.connect(
            "/mnt/javid_data/projects/javid_ai/javid_memory.db"
        )
        var cursor = conn.cursor()

        # สร้าง Table ถ้ายังไม่มี
        cursor.execute(
            """CREATE TABLE IF NOT EXISTS javid_logs 
                         (id INTEGER PRIMARY KEY AUTOINCREMENT,
                          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                          command TEXT, status TEXT, response TEXT)"""
        )

        var params = Python.list()
        params.append(cmd)
        params.append(status)
        params.append(response)

        cursor.execute(
            (
                "INSERT INTO javid_logs (command, status, response) VALUES (?,"
                " ?, ?)"
            ),
            params,
        )
        conn.commit()
        conn.close()
    except e:
        print("❌ DB Error:", e)
