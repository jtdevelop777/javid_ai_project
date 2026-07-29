from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import uvicorn
import zmq
import json
import threading
from pydantic import BaseModel
from typing import Dict, Any
from audio_serv import init_audio_routes
import signal
import sys



app = FastAPI(title="Javid MQ System API", version="1.0.0")
# หลังจากสร้าง app = FastAPI(...) แล้ว ให้เรียกผูก route ทันที
init_audio_routes(app)

_queue_size = 0
_queue_lock = threading.Lock()

def increment_queue():
    global _queue_size
    with _queue_lock:
        _queue_size += 1

def decrement_queue():
    global _queue_size
    with _queue_lock:
        if _queue_size > 0:
            _queue_size -= 1

def get_queue_size():
    global _queue_size
    with _queue_lock:
        return _queue_size

class TaskSchema(BaseModel):
    command: str

class IngestSchema(BaseModel):
    action: str
    payload: Dict[str, Any]

class MemorySchema(BaseModel):
    topic: str
    content: str
    category_id: int
    priority: int
    metadata: Dict[str, Any]

@app.get("/queue/status")
def get_queue_status():
    count = get_queue_size()
    return {
        "status": "success",
        "queue_position": count,
        "estimated_wait_seconds": count * 2,
        "message": f"There are {count} tasks waiting in the queue."
    }

@app.post("/ingest/memory")
def ingest_memory(data: MemorySchema):
    try:
        context = zmq.Context()
        sender = context.socket(zmq.PUSH)
        sender.connect("tcp://192.168.4.9:5555")
        
        msg_dict = {
            "action": "SAVE_MEMORY",
            "topic": data.topic,
            "content": data.content,
            "category_id": data.category_id,
            "priority": data.priority,
            "metadata": data.metadata
        }
        sender.send_string(json.dumps(msg_dict, ensure_ascii=False))
        increment_queue()
        return {"status": "queued", "message": "Memory ingested into ZMQ queue successfully."}
    except Exception as e:
        print(f"Error Detail: {e}")    

@app.post("/task")
def submit_task(data: TaskSchema):
    import zmq
    import json
    
    context = zmq.Context()
    sender = context.socket(zmq.PUSH)
    sender.connect("tcp://192.168.4.9:5555")
    
    msg_dict = {
        "auth_key": "ag_secure_local_token_2026",
        "target_version": "1.0.0",
        "command": str(data.command)
    }
    
    sender.send_string(json.dumps(msg_dict, ensure_ascii=False))
    increment_queue()
    return '{"status": "Success"}'

@app.post("/ingest")
def direct_ingest(data: IngestSchema):
    context = zmq.Context()
    sender = context.socket(zmq.PUSH)
    
    # 1. กำหนด Timeout การส่งไว้ 2 วินาที (ถ้าส่งไม่ได้ให้ตัด ไม่ค้าง LOADING)
    sender.setsockopt(zmq.SNDTIMEO, 2000)
    sender.setsockopt(zmq.LINGER, 0)
    
    # 2. ในเมื่อเป็นเครื่องเดียวกัน ใช้ 127.0.0.1 หรือ 192.168.4.9 ก็ได้
    sender.connect("tcp://127.0.0.1:5555")
    
    msg_dict = {"action": data.action, "payload": data.payload}
    
    try:
        sender.send_string(f"BYPASS_LOG:{json.dumps(msg_dict, ensure_ascii=False)}")
        increment_queue()
        return {"status": "Accepted", "mode": "FastTrack"}
    except zmq.Again:
        # ถ้าระบบส่งไม่ได้เพราะฝั่ง Mojo Worker (Port 5555) ยังไม่พร้อมรับ
        return {"status": "Error", "message": "Worker receiver unavailable on port 5555 (Timeout)"}
    finally:
        sender.close()
        context.term()

@app.websocket("/ws/sdr")
async def sdr_stream(websocket: WebSocket):
    await websocket.accept()
    print("[INFO] SDR Client connected.")
    try:
        while True:
            data = await websocket.receive_bytes()
            # print(f"[INFO] Received SDR chunk bytes. Size: {len(data)}")
            
            # --- [จุดประมวลผลข้อมูล SDR] นำ data ไปเข้ากระบวนการ DSP ต่อที่นี่ ---
            
            # ส่งผลลัพธ์หรือสถานะกลับไปหา Client (ถ้าต้องการ)
            response_payload = {
                "status": "success",
                "chunk_size": len(data),
                "message": "SDR chunk received."
            }
            await websocket.send_text(json.dumps(response_payload, ensure_ascii=False))
            
    except WebSocketDisconnect:
        print("[INFO] SDR connection closed.")
    except Exception as e:
        print(f"[ERROR] SDR WebSocket error: {e}")

def start_api(port=8001):
    uvicorn.run(app, host="0.0.0.0", port=port)

def start_api_bak(port=8001):
    # ปิด Access log ของ Uvicorn ไม่ให้บดบัง Log ของ Mojo (optional)
    config = uvicorn.Config(app, host="0.0.0.0", port=int(port), log_level="warning")
    server = uvicorn.Server(config)
    
    # ย้าย Uvicorn ไปวิ่งใน Daemon Thread เพื่อไม่ให้บล็อก Mojo Process
    t = threading.Thread(target=server.run, daemon=True)
    t.start()
    print(f"🚀 [API Server] Started asynchronously on port {port}")


