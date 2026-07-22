from std.python import Python, PythonObject
import std.time


struct ZmqBridge:
    var zmq: PythonObject
    var socket: PythonObject

    def __init__(out self, port: Int) raises:
        self.zmq = Python.import_module("zmq")
        var context = self.zmq.Context()
        self.socket = context.socket(self.zmq.PUB)
        self.socket.bind("tcp://*:" + String(port))
        print("🚀 ZMQ Bridge started on port:", port)

    def send_progress(self, job_id: String, percent: Int, msg: String) raises:
        var payload = (
            '{"job_id": "'
            + job_id
            + '", "progress": '
            + String(percent)
            + ', "status": "'
            + msg
            + '"}'
        )
        self.socket.send_string(payload)


# --- นี่คือส่วนที่ขาดไปครับ ---
def main() raises:
    # เริ่มต้นที่พอร์ต 8002 ตามแผน Port Running ของเรา
    var bridge = ZmqBridge(8002)

    # ทดสอบส่งสัญญาณประเมินเวลาและ Progress
    var job_id = "JAV-2026-001"
    print("Sending estimation and progress...")

    for i in range(0, 101, 25):
        bridge.send_progress(job_id, i, "Processing AI Logic...")
        print("Status sent:", i, "%")
        Python.import_module("time").sleep(1)

    print("✅ Test complete.")
