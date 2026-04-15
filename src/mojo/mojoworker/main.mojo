from std.python import Python, PythonObject
from taskModel import TaskModel
import services
import database

def main() raises:
    var py = Python.import_module("builtins")
    var sys = Python.import_module("sys")
    
    # --- จูงมือ Mojo ไปหา Library ใน Pixi Environment ---
    # เราใช้ path จาก which python ที่คุณส่งมา แล้วชี้ไปที่ site-packages
    # sys.path.append("/mnt/javid_data/projects/javid_ai/src/mojo/mojoworker/.pixi/envs/default/lib/python3.12/site-packages")
    
    # ทดสอบ import
    try:
        var fastapi = Python.import_module("fastapi")
        print("✅ พบ FastAPI ใน Pixi Environment แล้ว!")
    except:
        print("❌ ยังหา FastAPI ไม่เจอ ตรวจสอบ path อีกครั้งครับ")
        return

    var zmq = Python.import_module("zmq")
    var threading = Python.import_module("threading")
    
    # --- ใช้ bridge_code ท่าเดิม (Single File) ---
    var bridge_code = """
from fastapi import FastAPI
import uvicorn
import zmq
from fastapi import WebSocket

app = FastAPI()

@app.post("/task")
def submit_task(data: dict):
    context = zmq.Context()
    sender = context.socket(zmq.PUSH)
    sender.connect("tcp://localhost:5555")
    sender.send_string(data.get("command", ""))
    return {"status": "Success"}


# เลนด่วน (Bypass - ยิงเข้า ZMQ 5556 หรือส่ง JSON ทั้งก้อน)
@app.post("/ingest")
def direct_ingest(data: dict):
    context = zmq.Context()
    sender = context.socket(zmq.PUSH)
    sender.connect("tcp://localhost:5555") # หรือจะแยก Port เป็น 5556 ก็ได้ถ้าอยากแยกเลนจริงจัง
    
    # ส่งข้อมูลดิบเป็น String JSON กลับไปให้ Mojo Worker เป็นคนบันทึก DB
    import json
    sender.send_string(f"BYPASS_LOG:{json.dumps(data)}")
    
    return {"status": "Accepted", "mode": "FastTrack"}   

@app.websocket("/ws/sdr")
async def sdr_stream(websocket: WebSocket):
    await websocket.accept()
    while True:
        # รับข้อมูล Binary จาก Mojo (SDR Stream)
        data = await websocket.receive_bytes() 
        # ส่งต่อให้ระบบประมวลผล หรือบันทึกลงไฟล์ด่วน
        save_sdr_chunk(data)     

def start_api(port):
    uvicorn.run(app, host="0.0.0.0", port=port)
"""
    var scope = Python.dict()
    _ = py.exec(bridge_code, scope)
    var start_api = scope["start_api"]

    # --- รัน API Thread ---
    var thread_kwargs = Python.dict()
    thread_kwargs["port"] = 8001
    
    var server_thread = threading.Thread(
        target=start_api, 
        kwargs=thread_kwargs
    )
    server_thread.setDaemon(True)
    server_thread.start()

    # --- ZMQ Receiver Loop ---
    var context = zmq.Context()
    var receiver = context.socket(zmq.PULL)
    receiver.bind("tcp://*:5555")
    var publisher = context.socket(zmq.PUB)
    publisher.bind("tcp://*:8002")
    
    print("🚀 Javid MQ System: Mojo + Pixi [PORT 8001 ONLINE]")
    
    while True:
        var raw_msg = receiver.recv_string()
        var task = TaskModel(String(raw_msg)) 
        
        publisher.send_string(task.to_json("estimation")) 
        print("⏳ Task Received: " + task.command)

        if "พักผ่อน" in task.command:
            task.response = "สรุปงาน: ระบบรวมร่าง Mojo+FastAPI ผ่าน Pixi สำเร็จ [ai_tag: 15042026_0045]"
            database.log_to_sqlite(task.command, "COMPLETED", task.response)
            publisher.send_string(task.to_json("answer"))
            print("💤 พักผ่อนได้ครับกัปตัน!")
            break
        else:
            task.response = services.ask_ollama(task.command)
            database.log_to_sqlite(task.command, "COMPLETED", task.response)
            publisher.send_string(task.to_json("answer"))
            print("✨ งานเรียบร้อย")

