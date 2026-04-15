from std.python import Python

def main() raises:
    # 1. เรียก import_module ผ่าน Python ตรงๆ เลยครับ
    var zmq = Python.import_module("zmq")
    var requests = Python.import_module("requests")
    
    var context = zmq.Context()
    
    # ท่อรับคำสั่ง (PULL) - พอร์ต 5555
    var receiver = context.socket(zmq.PULL)
    receiver.bind("tcp://*:5555")
    
    # ท่อกระจายข่าว (PUB) - พอร์ต 8002
    var publisher = context.socket(zmq.PUB)
    publisher.bind("tcp://*:8002")
    
    print("------------------------------------------")
    print("🚀 Javid MQ System: Active [5555:PULL / 8002:PUB]")
    print("Mojo AI Worker พร้อมเชื่อมต่อ Ollama แล้ว...")
    print("------------------------------------------")
    
    while True:
        # รับงานปุ๊บ (ระบบจะหยุดรอตรงนี้จนกว่า Client จะส่งมา)
        var msg = receiver.recv_string()
        var message = String(msg)
        print("📩 [PULL]: กัปตันสั่งมาว่า:", message)

        # 1. ประเมินเวลาและส่งออกทาง PUB (8002) ทันที
        # var est_wait = 1.5 + (Float64(message.byte_length()) / 50.0)
        var est_wait = 5.0 + (Float64(message.byte_length()) / 10.0) # ปรับตัวหารให้เล็กลงเพื่อให้เวลาเพิ่มขึ้น
        publisher.send_string('{"type": "estimation", "value": ' + String(est_wait) + '}')
        print("⏳ [PUB]: ส่งเวลาประเมิน ->", est_wait, "วินาที")

        # 2. ไปถาม Ollama จริงๆ 
        var url = "http://localhost:11434/api/generate"
        var payload = Python.dict() # ใช้ Python.dict() ตรงๆ
        payload["model"] = "llama3"
        payload["prompt"] = message
        payload["stream"] = False

        print("🤖 กำลังถาม Ollama...")
        var response = requests.post(url, json=payload)
        
        var ai_reply: String
        if response.status_code == 200:
            ai_reply = String(response.json()["response"])
        else:
            ai_reply = String("ขออภัยครับกัปตัน ติดต่อ Ollama ไม่ได้")

        # 3. ส่งคำตอบจริงออกทาง PUB (8002)
        # --- ใน server.mojo ช่วงที่ได้ ai_reply มาแล้ว ---
        var ai_reply_safe = ai_reply.replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r')

        # แล้วค่อยส่งออกไป
        publisher.send_string('{"type": "answer", "value": "' + ai_reply_safe + '"}')
        print("✨ [PUB]: ส่งคำตอบสำเร็จ")        

        # 4. บันทึก DB
        save_to_db(message, ai_reply)

def save_to_db(user_msg: String, ai_msg: String):
    try:
        var sqlite3 = Python.import_module("sqlite3")
        var conn = sqlite3.connect("javid_memory.db")
        var cursor = conn.cursor()
        cursor.execute("CREATE TABLE IF NOT EXISTS history (user_cmd TEXT, ai_response TEXT)")
        var params = Python.list()
        params.append(user_msg)
        params.append(ai_msg)
        cursor.execute("INSERT INTO history (user_cmd, ai_response) VALUES (?, ?)", params)
        conn.commit()
        conn.close()
    except e:
        pass # ปล่อยผ่านถ้า DB มีปัญหา เพื่อไม่ให้ระบบหลักหยุดทำงาน