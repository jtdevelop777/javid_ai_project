# main_memory_api.py

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, List
import zmq
import zmq.asyncio
import datetime
import chromadb
import asyncio

# =========================
# INIT APP
# =========================
app = FastAPI(title="Javid AI Memory Core", version="2.0.0")

# =========================
# ZeroMQ (Event Bus)
# =========================
# แก้ไขส่วนการประกาศ Socket ให้เป็น Async เต็มตัว
ctx = zmq.asyncio.Context()
zmq_sock = ctx.socket(zmq.PUB)
# ไม่ต้อง bind ซ้ำถ้ามีการรันใหม่บ่อยๆ หรือใช้ Try-Except คลุมไว้ครับ
try:
    zmq_sock.bind("tcp://0.0.0.0:5555")
except zmq.ZMQError:
    pass

# =========================
# Chroma (AI Memory)
# =========================
# chroma_client = chromadb.HttpClient(host="localhost", port=8000)
# จากเดิม 8000 เปลี่ยนเป็น 8002
chroma_client = chromadb.HttpClient(host="localhost", port=8002)

collection = chroma_client.get_or_create_collection(
    name="javid_semantic_memory"
)

# =========================
# Models
# =========================
class KnowledgeEntry(BaseModel):
    topic: str
    content: str
    ai_tag: Optional[str] = None
    category_id: int
    priority: Optional[int] = 2
    metadata: Optional[Dict] = {}

class SearchQuery(BaseModel):
    query: str
    top_k: Optional[int] = 3

# =========================
# Utils
# =========================
def generate_tag():
    return "AI_TAG_D:" + datetime.datetime.now().strftime("%y%m%d_%H%M%S")

# =========================
# Startup / Shutdown
# =========================
@app.on_event("startup")
async def startup_event():
    print("🚀 Javid Memory API Started (Chroma + ZMQ)")

@app.on_event("shutdown")
async def shutdown_event():
    zmq_sock.close()
    ctx.term()

# =========================
# Root
# =========================
@app.get("/")
async def root():
    return {
        "status": "ok",
        "service": "Javid Memory Core",
        "chroma": "connected",
        "zmq_port": 5555
    }

# =========================
# 1. SAVE MEMORY
# =========================
@app.post("/api/v1/memory/save")
async def save_memory(entry: KnowledgeEntry):
    try:
        tag = entry.ai_tag or generate_tag()

        # 🔹 Save to Chroma
        collection.add(
            documents=[entry.content],
            metadatas=[{
                "topic": entry.topic,
                "category_id": entry.category_id,
                "priority": entry.priority,
                **entry.metadata
            }],
            ids=[tag]
        )

        # 🔹 Broadcast event
        await zmq_sock.send_json({
            "event": "MEMORY_SAVED",
            "tag": tag,
            "topic": entry.topic,
            "timestamp": str(datetime.datetime.now())
        })

        return {
            "status": "success",
            "ai_tag": tag
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =========================
# 2. SEARCH MEMORY
# =========================
# เพิ่มตัวเลือกการกรองข้อมูลใน Search
@app.post("/api/v1/memory/search")
async def search_memory(query: SearchQuery):
    try:
        results = collection.query(
            query_texts=[query.query],
            n_results=query.top_k,
            # เพิ่ม include เพื่อเอา metadata และ distance มาวิเคราะห์ความแม่นยำ
            include=["documents", "metadatas", "distances"] 
        )
        return {"status": "success", "results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =========================
# 3. DELETE MEMORY
# =========================
@app.delete("/api/v1/memory/{ai_tag}")
async def delete_memory(ai_tag: str):
    try:
        collection.delete(ids=[ai_tag])

        return {
            "status": "deleted",
            "ai_tag": ai_tag
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =========================
# 4. AUTO SUMMARY + SAVE
# =========================
@app.post("/api/v1/memory/auto-save")
async def auto_save_memory(text: str):
    """
    ใช้สำหรับ:
    - สรุปบทสนทนา
    - เก็บ memory อัตโนมัติ
    """
    try:
        tag = generate_tag()

        # (ตอนนี้ใช้ text ตรง ๆ ก่อน)
        summary = text[:1000]

        collection.add(
            documents=[summary],
            metadatas=[{
                "topic": "auto_summary",
                "priority": 2
            }],
            ids=[tag]
        )

        return {
            "status": "auto_saved",
            "ai_tag": tag
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =========================
# 5. HEALTH CHECK
# =========================
@app.get("/api/v1/health")
async def health():
    return {
        "status": "healthy",
        "services": {
            "chroma": "ok",
            "zmq": "ok"
        }
    }

## bash uvicorn main_memory_api:app --reload --port 8001
