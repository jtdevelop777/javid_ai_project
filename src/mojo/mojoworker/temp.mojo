from std.python import Python, PythonObject
from taskModel import TaskModel
import services
import database


def main() raises:
    var py = Python.import_module("builtins")
    var fastapi = Python.import_module("fastapi")
    var uvicorn = Python.import_module("uvicorn")
    var threading = Python.import_module("threading")  # ใช้ช่วยรัน Loop แยก

    # --- ส่วนของ ZMQ เดิม ---
    var zmq = Python.import_module("zmq")
    var context = zmq.Context()
    var receiver = context.socket(zmq.PULL)
    receiver.bind("tcp://*:5555")
    # ... (โค้ดส่วน publisher เดิมของคุณ) ...

    # --- ส่วนของ FastAPI (สร้างภายใน Mojo) ---
    var app = fastapi.FastAPI()

    @parameter
    def submit_task(cmd: PythonObject) raises -> PythonObject:
        # ตรงนี้คือจุดที่ FastAPI จะส่งงานเข้า ZMQ PULL ของเราเอง
        var ctx = Python.import_module("zmq").Context()
        var sender = ctx.socket(Python.import_module("zmq").PUSH)
        sender.connect("tcp://192.168.4.9:5555")
        sender.send_string(cmd)
        return Python.dict(status="Success", msg="Task sent to Mojo Queue")

    app.post("/task")(submit_task)

    # รัน FastAPI แยก Thread เพื่อไม่ให้กวน While Loop หลักของ ZMQ
    var server_thread = threading.Thread(
        target=uvicorn.run,
        args=(app,),
        kwargs={"host": "0.0.0.0", "port": 8001},
    )
    server_thread.start()

    print("🚀 Javid MQ + FastAPI: Hybrid System [READY]")

    # --- While Loop เดิมของคุณ ---
    while True:
        var raw_msg = receiver.recv_string()
        var task = TaskModel(String(raw_msg))

        # ส่งสถานะเริ่มงาน
        publisher.send_string(task.to_json("estimation"))
        print("⏳ ส่งเวลาประเมิน: " + String(task.estimated_sec) + " วินาที")

        if "พักผ่อน" in task.command:
            task.response = (
                "สรุปงาน: ระบบ Modular เสร็จสมบูรณ์ทุกไฟล์ [ai_tag:"
                " 15042026_0045]"
            )
            database.log_to_sqlite(task.command, "COMPLETED", task.response)
            publisher.send_string(task.to_json("answer"))
            print("💤 ภารกิจจบสิ้น พักผ่อนได้ครับกัปตัน!")
            break
        else:
            # ใช้บริการจากไฟล์ย่อย
            task.response = services.ask_ollama(task.command)
            database.log_to_sqlite(task.command, "COMPLETED", task.response)
            publisher.send_string(task.to_json("answer"))
            print("✨ งานเรียบร้อย")
