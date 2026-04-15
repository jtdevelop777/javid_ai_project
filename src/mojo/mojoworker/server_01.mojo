from std.python import Python

def main():
    try:
        zmq = Python.import_module("zmq")
        requests = Python.import_module("requests") # ต้องมีตัวนี้เพื่อคุยกับ Ollama API
        
        context = zmq.Context()
        socket = context.socket(zmq.REP)
        socket.bind("tcp://*:5555")
        
        print("Mojo AI Worker พร้อมเชื่อมต่อ Ollama แล้ว...")
        
        while True:
            # 1. รับข้อความจากกัปตัน
            py_message = socket.recv_string()
            message = String(py_message)
            print("กัปตันสั่งมาว่า:", message)

            # 2. ส่งต่อให้ Ollama (สมมติว่า Ollama รันอยู่ที่ port 11434)
            url = "http://localhost:11434/api/generate"
            # สร้าง Payload ส่งหา Llama 3
            payload = Python.dict()
            payload["model"] = "llama3"
            payload["prompt"] = "ในฐานะผู้ช่วยของกัปตัน Jack ช่วยตอบคำถามนี้สั้นๆ: " + message
            payload["stream"] = False

            print("กำลังถาม Ollama...")
            response = requests.post(url, json=payload)
            
            # 3. ดึงคำตอบจาก Ollama
            if response.status_code == 200:
                ai_reply = response.json()["response"]
            else:
                ai_reply = "ขออภัยครับกัปตัน ติดต่อ Ollama ไม่ได้"

            print("Ollama ตอบว่า:", ai_reply)

            # 4. ส่งคำตอบกลับไปที่ Client
            socket.send_string(String(ai_reply))
            
    except e:
        print("เกิดข้อผิดพลาด:", e)

def save_to_db(user_msg: String, ai_msg: String):
    try:
        sqlite3 = Python.import_module("sqlite3")
        conn = sqlite3.connect("javid_memory.db")
        cursor = conn.cursor()
        
        # สร้างตารางถ้ายังไม่มี
        cursor.execute('''CREATE TABLE IF NOT EXISTS history 
                         (timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, 
                          user_cmd TEXT, ai_response TEXT)''')
        
        # บันทึกข้อมูล
        cursor.execute("INSERT INTO history (user_cmd, ai_response) VALUES (?, ?)", 
                       [user_msg, ai_msg])
        
        conn.commit()
        conn.close()
        print("--- บันทึก Know-how ลงฐานข้อมูลเรียบร้อย ---")
    except e:
        print("DB Error:", e)        