# main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict
import zmq
import zmq.asyncio # ใช้แบบ Async เพื่อไม่ให้ Block FastAPI
import asyncio
import datetime

app = FastAPI(title="Javid AI Core with ZeroMQ", version="1.1.0")

# --- ZeroMQ Setup ---
# Context สำหรับจัดการ ZeroMQ
ctx = zmq.asyncio.Context()
# สมมติใช้แบบ PUB เพื่อส่งข้อมูลกระจายไปยังโมดูลอื่น (เช่น SDR หรือ GUI)
zmq_sock = ctx.socket(zmq.PUB)
zmq_sock.bind("tcp://0.0.0.0:5555") # ใช้พอร์ต 5555 สำหรับ ZeroMQ

class KnowledgeEntry(BaseModel):
    topic: str
    content: str
    ai_tag: str
    category_id: int
    metadata: Optional[Dict] = {}

@app.on_event("startup")
async def startup_event():
    print("🚀 Javid API & ZeroMQ Socket (Port 5555) Started")

@app.get("/")
async def root():
    return {"message": "Javid API & ZeroMQ are Live", "zmq_port": 5555}

@app.post("/api/v1/knowledge")
async def create_knowledge(entry: KnowledgeEntry):
    try:
        # 1. บันทึกเข้า DB (กัปตันจัดการส่วน SQL ต่อได้เลย)
        
        # 2. ส่งข้อมูลออกทาง ZeroMQ ทันที (Real-time Broadcast)
        # ส่ง ai_tag และหัวข้อออกไปเพื่อให้โมดูลอื่นรับทราบ
        await zmq_sock.send_json({
            "event": "NEW_KNOWLEDGE",
            "tag": entry.ai_tag,
            "topic": entry.topic,
            "timestamp": str(datetime.datetime.now())
        })
        
        return {
            "status": "success",
            "message": "Data saved and broadcasted via ZeroMQ"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.on_event("shutdown")
async def shutdown_event():
    zmq_sock.close()
    ctx.term()
