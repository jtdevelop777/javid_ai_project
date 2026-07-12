from std.python import Python, PythonObject
from taskModel import TaskModel
import services
import database

def main() raises:
    var py = Python.import_module("builtins")
    var sys = Python.import_module("sys")
    
    # ทดสอบ import
    try:
        var fastapi = Python.import_module("fastapi")
        print("✅ พบ FastAPI ใน Pixi Environment แล้ว!")
    except:
        print("❌ ยังหา FastAPI ไม่เจอ ตรวจสอบ path อีกครั้งครับ")
        return

    var zmq = Python.import_module("zmq")
    var threading = Python.import_module("threading")
    
    # --- ใช้ bridge_code ฉบับปรับปรุง UTF-8 Encoding สมบูรณ์ ---
    var bridge_code = """
from fastapi import FastAPI, WebSocket
import uvicorn
import zmq
import json
from pydantic import BaseModel
from typing import Dict, Any

app = FastAPI(title="Javid MQ System API", version="1.0.0")

# --- นิยาม Schema เพื่อแก้ปัญหาหน้า Swagger UI ว่างเปล่า ---
class TaskSchema(BaseModel):
    command: str

class IngestSchema(BaseModel):
    action: str
    payload: Dict[str, Any]

@app.post("/task")
def submit_task(data: TaskSchema):
    context = zmq.Context()
    sender = context.socket(zmq.PUSH)
    sender.connect("tcp://localhost:5555")
    
    # แก้ไข: บังคับ ensure_ascii=False เพื่อให้ภาษาไทยคงสภาพ UTF-8 ไม่กลายเป็นรหัสต่างดาว
    msg_dict = {"command": data.command}
    sender.send_string(json.dumps(msg_dict, ensure_ascii=False))
    return {"status": "Success"}

@app.post("/ingest")
def direct_ingest(data: IngestSchema):
    context = zmq.Context()
    sender = context.socket(zmq.PUSH)
    sender.connect("tcp://localhost:5555")
    
    msg_dict = {
        "action": data.action,
        "payload": data.payload
    }
    # แก้ไข: บังคับ ensure_ascii=False ป้องกันภาษาไทยเพี้ยนในเลนด่วน
    sender.send_string(f"BYPASS_LOG:{json.dumps(msg_dict, ensure_ascii=False)}")
    return {"status": "Accepted", "mode": "FastTrack"}   

@app.websocket("/ws/sdr")
async def sdr_stream(websocket: WebSocket):
    await websocket.accept()
    while True:
        data = await websocket.receive_bytes() 
        # ฟังก์ชันรองรับการเซฟ chunk ข้อมูล SDR
        # save_sdr_chunk(data)     
        pass

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
            task.response = "สรุปงาน: แก้ไขปัญหาภาษาไทยต่างดาว (Encoding) ในระบบคิว Mojo+FastAPI ผ่าน ZMQ สำเร็จ [ai_tag: 13072026_0001]"
            database.log_to_sqlite(task.command, "COMPLETED", task.response)
            publisher.send_string(task.to_json("answer"))
            print("💤 พักผ่อนได้ครับกัปตัน!")
            break
        else:
            task.response = services.ask_ollama(task.command)
            database.log_to_sqlite(task.command, "COMPLETED", task.response)
            publisher.send_string(task.to_json("answer"))
            print("✨ งานเรียบร้อย")