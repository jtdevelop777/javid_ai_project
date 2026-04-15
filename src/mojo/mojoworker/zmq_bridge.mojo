from python import Python
import time

struct ZmqBridge:
    var zmq: PythonObject
    var socket: PythonObject

    fn __init__(inout self, port: Int) raises:
        self.zmq = Python.import_module("zmq")
        let context = self.zmq.Context()
        self.socket = context.socket(self.zmq.PUB)
        self.socket.bind("tcp://*:" + str(port))
        print("🚀 ZMQ Bridge started on port:", port)

    fn send_progress(self, job_id: String, percent: Int, msg: String) raises:
        let payload = '{"job_id": "' + job_id + '", "progress": ' + str(percent) + ', "status": "' + msg + '"}'
        self.socket.send_string(payload)

# --- นี่คือส่วนที่ขาดไปครับ ---
fn main() raises:
    # เริ่มต้นที่พอร์ต 8002 ตามแผน Port Running ของเรา
    let bridge = ZmqBridge(8002)
    
    # ทดสอบส่งสัญญาณประเมินเวลาและ Progress
    let job_id = "JAV-2026-001"
    print("Sending estimation and progress...")
    
    for i in range(0, 101, 25):
        bridge.send_progress(job_id, i, "Processing AI Logic...")
        print("Status sent:", i, "%")
        time.sleep(1)
        
    print("✅ Test complete.")