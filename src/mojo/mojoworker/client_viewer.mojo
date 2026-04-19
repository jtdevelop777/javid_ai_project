from std.python import Python
import database

def main() raises:
    var py = Python.import_module("builtins")
    var zmq = Python.import_module("zmq")
    var json = Python.import_module("json")

    # --- 1. ตั้งค่าการเชื่อมต่อ (Subscriber) ---
    var context = zmq.Context()
    var subscriber = context.socket(zmq.SUB)
    
    # เชื่อมไปที่ Port 8002 ที่ Mojo หลักพ่นข้อมูลออกมา
    subscriber.connect("tcp://localhost:8002")
    
    # ตั้งค่าให้รับทุกข้อความ (Filter ว่างไว้)
    subscriber.setsockopt_string(zmq.SUBSCRIBE, "")

    print("----------------------------------------")
    print("📺 Javid Monitor: กำลังดักรอคำตอบจาก Mojo...")
    print("📡 Connected to: tcp://localhost:8002")
    print("----------------------------------------")

    while True:
            try:
                # รอรับข้อมูล
                var raw_msg = subscriber.recv_string()
                var data = json.loads(raw_msg)
                
                # ตรวจสอบก่อนว่ามี Key ครบไหม (กันเหนียว)
                # หรือใช้ try ครอบเฉพาะตอนดึงค่า
                var est_time = py.str(data["estimate"])
                var task_id = py.str(data["id"])
                var cmd = py.str(data["command"])
                var resp = py.str(data["response"])
                var status = py.str(data["status"])

                print("\n📩 [ได้รับข้อมูลใหม่]")
                print("🆔 ID      : " + String(task_id))
                # ... (print ส่วนที่เหลือ) ...

            except e:
                # ถ้าเกิด Error ใน loop ให้แจ้งเตือนแต่ไม่ต้องหยุดรัน
                print(e)
                print("⚠️ ข้อมูลที่ได้รับมีรูปแบบไม่ถูกต้อง หรือรอรับข้อมูลนานเกินไป")
                # ไม่ต้องใส่ break; เพื่อให้มันวนกลับไปรอ recv_string ใหม่