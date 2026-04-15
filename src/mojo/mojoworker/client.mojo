from std.python import Python

def main():
    try:
        zmq = Python.import_module("zmq")
        
        context = zmq.Context()
        socket = context.socket(zmq.REQ) # แบบ Request
        socket.connect("tcp://localhost:5555")
        
        print("กัปตัน Jack กำลังส่งคำสั่ง...")
        socket.send_string("เริ่มภารกิจ AI Tag 2026-04-14")
        
        # รอรับคำตอบ
        reply = socket.recv_string()
        print("ข้อความตอบกลับ:", reply)
        
        # เพิ่ม 2 บรรทัดนี้ก่อนจบ try
        socket.close()
        context.term()        
        
    except e:
        print("เกิดข้อผิดพลาด:", e)
