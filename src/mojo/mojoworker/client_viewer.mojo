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

    try:
        while True:
            # รอรับข้อมูล (Blocking call)
            var raw_msg = subscriber.recv_string()
            var data = json.loads(raw_msg)
            
            # 2. ดึงข้อมูลออกมาแสดงผล
            # หมายเหตุ: ใช้ py.str() เพื่อความชัวร์ในการดึงค่าจาก Python dict ใน Mojo
            var task_id = py.str(data["id"])
            var cmd = py.str(data["command"])
            var resp = py.str(data["response"])
            var status = py.str(data["status"])

            print("\n📩 [ได้รับข้อมูลใหม่]")
            print("🆔 ID      : " + String(task_id))
            print("💬 คำสั่ง   : " + String(cmd))
            print("✅ ผลลัพธ์ : " + String(resp))
            print("📊 สถานะ   : " + String(status))
            print("----------------------------------------")
            
    except:
        print("\n🛑 ปิดระบบ Monitor")