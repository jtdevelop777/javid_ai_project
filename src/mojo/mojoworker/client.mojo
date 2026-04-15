from std.python import Python

def main() raises:
    var zmq = Python.import_module("zmq")
    var json = Python.import_module("json")
    
    var context = zmq.Context()
    
    # 1. ท่อส่ง (PUSH) ไปพอร์ต 5555
    var sender = context.socket(zmq.PUSH)
    sender.connect("tcp://localhost:5555")
    
    # 2. ท่อรับ (SUB) จากพอร์ต 8002
    var subscriber = context.socket(zmq.SUB)
    subscriber.connect("tcp://localhost:8002")
    subscriber.setsockopt_string(zmq.SUBSCRIBE, "") 
    
    # 3. เตรียม Poller เพื่อไม่ให้หน้าจอค้าง
    var poller = zmq.Poller()
    poller.register(subscriber, zmq.POLLIN)
    
    print("------------------------------------------")
    print("🚀 Javid MQ Client: กำลังยิงคำสั่งเข้าคิว...")
    
    # --- บรรทัดที่ส่งคำสั่งจริง ---
    sender.send_string("กัปตัน Jack สั่งเริ่มภารกิจ AI Tag 15042026")
    
    print("✅ ส่งสำเร็จ! (หน้าจอไม่ค้าง กัปตันรอรับสถานะได้เลย)")
    print("------------------------------------------")
    
    while True:
        # เช็ค Message จากพอร์ต 8002 (รอรอบละ 100ms)
        var socks = poller.poll(100)
        
        if socks: 
            var msg = subscriber.recv_string(flags=zmq.NOBLOCK)
            var data = json.loads(msg)
            
            if data["type"] == "estimation":
                print("⏳ [MQ Status]: ระบบได้รับงานแล้ว คาดว่าใช้เวลา", data["value"], "วินาที")
            #elif data["type"] == "answer":
            #    print("✨ [MQ Answer]: AI ตอบกลับมาว่า ->", data["value"])
            #    print("\n--- จบภารกิจ (กด Ctrl+C เพื่อออก) ---")
            elif data["type"] == "answer":
                print("✨ [MQ Answer]: AI ตอบกลับมาว่า ->", data["value"])
                print("\n--- ภารกิจเสร็จสิ้น ---")
                return # ใส่ return ตรงนี้เพื่อให้ออกจาก while loop และจบโปรแกรมครับ                