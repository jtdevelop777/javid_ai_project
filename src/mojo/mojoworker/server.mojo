from std.python import Python

def main():
    try:
        zmq = Python.import_module("zmq")
        
        context = zmq.Context()
        socket = context.socket(zmq.REP)
        socket.bind("tcp://*:5555")
        
        print("Mojo ZMQ Server กำลังรอรับข้อมูลที่ Port 5555...")
        
        while True:
                    # 1. รับ Message มา (ตัวนี้เป็น Python Object)
                    py_message = socket.recv_string()
                    
                    # 2. แปลงให้เป็น Mojo String ชัดเจน
                    var message = String(py_message) 
                    
                    print("ได้รับข้อความจากลูกเรือ:", message)
                    
                    # 3. ต่อ String แบบ Mojo (ใช้ + ได้แล้วเพราะเป็น Mojo String ทั้งคู่)
                    var reply_text = "อาจารย์เจมส์ได้รับแล้ว: " + message
                    
                    socket.send_string(reply_text)
            
    except e:
        print("เกิดข้อผิดพลาด:", e)
