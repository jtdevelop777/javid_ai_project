from std.python import Python, PythonObject
import std.time


# 1. ส่วนประเมินเวลา (Estimation)
struct JavidEstimator:
    def __init__(out self):
        pass

    def estimate(self, query: String) -> Float64:
        var length = query.byte_length()
        # สูตร: พื้นฐาน 1.5 วิ + (จำนวนอักษร / 50) * 1 วินาที
        return 1.5 + (Float64(length) / 50.0)


# 2. ส่วนส่งสัญญาณ Progress (ZMQ Bridge)
struct JavidBridge:
    var zmq: PythonObject
    var pub_socket: PythonObject

    def __init__(out self, port: Int) raises:
        self.zmq = Python.import_module("zmq")
        var context = self.zmq.Context()
        self.pub_socket = context.socket(self.zmq.PUB)
        # ใช้ Port 8002 ตามแผน Port Running ของเรา
        self.pub_socket.bind("tcp://*:" + String(port))

    def broadcast_status(
        self, job_id: String, progress: Int, status: String
    ) raises:
        var payload = (
            '{"job_id": "'
            + job_id
            + '", "progress": '
            + String(progress)
            + ', "status": "'
            + status
            + '"}'
        )
        self.pub_socket.send_string(payload)


# 3. Main Workflow (ตัวอย่างการใช้งานร่วมกัน)
def main() raises:
    var estimator = JavidEstimator()
    var bridge = JavidBridge(8002)

    var user_query = "ช่วยสรุปรายงานโครงการ Lalin Property ให้หน่อย"
    var job_id = "JOB-15042026-001"

    # ขั้นตอนที่ 1: ประเมินและแจ้งทันที
    var wait_time = estimator.estimate(user_query)
    print("Estimated Wait:", wait_time, "sec")
    bridge.broadcast_status(
        job_id, 0, "Received: Estimated " + String(wait_time) + "s"
    )

    # ขั้นตอนที่ 2: จำลองการทำงาน (ส่งต่อไปยัง Ollama/Flowise)
    # ในงานจริงตรงนี้จะเรียก Python Interop เพื่อคุยกับ Flowise
    for i in range(1, 6):
        Python.import_module("time").sleep(1)
        var progress_pct = i * 20
        bridge.broadcast_status(
            job_id, progress_pct, "Processing with Ollama..."
        )

    bridge.broadcast_status(job_id, 100, "Done!")
