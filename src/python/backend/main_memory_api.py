## uvicorn main_memory_api:app --reload --port 80001
import datetime
import asyncio
import httpx
import zmq
import zmq.asyncio
import chromadb
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, List
import json
import urllib.request

# ==========================================
# 1. INIT APP & ASYNC ZMQ (Event Bus)
# ==========================================
app = FastAPI(title="Javid AI Memory Core", version="2.3.0")

ctx = zmq.asyncio.Context()
zmq_sock = ctx.socket(zmq.PUB)

try:
    zmq_sock.bind("tcp://0.0.0.0:5555")
    print("✅ [อ.เจมส์] ZMQ Event Bus พร้อมทำงานที่พอร์ต 5555")
except zmq.ZMQError as e:
    print(f"⚠️ [อ.เจมส์] ZMQ Warning: {e} - Skipping bind (พอร์ตอาจถูกจองอยู่)")

# ==========================================
# 2. CHROMA DB CONNECTION (Port 8002)
# ==========================================
chroma_client = chromadb.HttpClient(host="127.0.0.1", port=8002)
collection = chroma_client.get_or_create_collection(name="javid_semantic_memory")

# ==========================================
# 3. DATA MODELS
# ==========================================
class KnowledgeEntry(BaseModel):
    topic: str
    content: str
    ai_tag: Optional[str] = None
    category_id: int
    metadata: Optional[Dict] = {}

class AskRequest(BaseModel):
    question: str
    category_id: Optional[int] = None

class SearchQuery(BaseModel):
    query: str
    top_k: Optional[int] = 3
    category_id: Optional[int] = None

# ==========================================
# 4. WORKER (Ollama Caller)
# ==========================================
def call_ollama_raw(prompt: str):
    """ฟังก์ชันทำงานแบบ Synchronous สำหรับ Background Task"""
    url = "http://127.0.0.1:11434/api/generate"
    payload = {
        "model": "phi3:mini",
        "prompt": prompt,
        "stream": False
    }
    data = json.dumps(payload).encode('utf-8')
    
    # แก้ไขตัวแปร req ให้กัปตันแล้วครับ
    req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})

    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            raw_body = response.read().decode('utf-8')
            res_data = json.loads(raw_body)
            print(f"✅ AI Response: {res_data.get('response')[:100]}...")
            return res_data.get('response')

    except urllib.error.HTTPError as e:
        print(f"🛑 SERVER ERROR: {e.code} - {e.read().decode('utf-8')}")
    except Exception as e:
        print(f"❌ Network Level Error: {str(e)}")

# ==========================================
# 5. API ENDPOINTS
# ==========================================

@app.get("/api/v1/health")
async def health():
    return {"status": "alive", "engine": "Achan James Core", "time": str(datetime.datetime.now())}

@app.post("/api/v1/memory/save")
async def save_memory(entry: KnowledgeEntry):
    try:
        # ใช้ Format Tag ตามธรรมนูญเรา: DDMMYYYY_XXXX
        today = datetime.datetime.now().strftime('%d%m%Y')
        tag = entry.ai_tag or f"{today}_{datetime.datetime.now().strftime('%H%M%S')}"
        
        collection.add(
            documents=[entry.content],
            metadatas=[{"topic": entry.topic, "category_id": entry.category_id, **entry.metadata}],
            ids=[tag]
        )
        
        # ส่งสัญญาณออกทาง ZMQ
        await zmq_sock.send_json({"event": "MEMORY_SAVED", "tag": tag, "topic": entry.topic})
        
        return {"status": "success", "ai_tag": tag, "message": "อ.เจมส์ บันทึกความจำให้แล้วครับ!"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/memory/search")
async def search_memory(query: SearchQuery):
    try:
        where_filter = {"category_id": query.category_id} if query.category_id else {}
        results = collection.query(
            query_texts=[query.query], 
            n_results=query.top_k, 
            where=where_filter,
            include=["documents", "metadatas", "distances"]
        )
        return {"status": "success", "results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/memory/ask")
async def ask_javid(request: AskRequest):
    try:
        # 1. Retrieval: ดึงความจำเก่า
        where_filter = {"category_id": request.category_id} if request.category_id else {}
        results = collection.query(query_texts=[request.question], n_results=2, where=where_filter)
        
        context = "\n".join(results['documents'][0]) if results['documents'] and results['documents'][0] else "ไม่มีข้อมูลเดิม"
        
        # 2. ปรุง Prompt สไตล์ อ.เจมส์
        prompt = f"""คุณคือ อ.เจมส์ ที่ปรึกษา AI ตอบกัปตันจักร์ชัยแบบเพื่อนสนิท จริงใจ ยึดหลักศีล 5
        ความจำเดิม: {context}
        คำถามจากกัปตัน: {request.question}
        ตอบกัปตันว่า:"""
        
        # 3. รัน Background Task (เรียก Ollama หลังบ้าน)
        loop = asyncio.get_running_loop()
        loop.run_in_executor(None, call_ollama_raw, prompt)
        
        return {
            "status": "Accepted",
            "message": "อ.เจมส์ รับเรื่องแล้วครับกัปตัน! กำลังประมวลผลหลังบ้านนะ",
            "ref_tags": results['ids'][0] if results['ids'] else []
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/v1/memory/{ai_tag}")
async def delete_memory(ai_tag: str):
    try:
        collection.delete(ids=[ai_tag])
        return {"status": "deleted", "ai_tag": ai_tag, "message": "ลบความจำส่วนนี้ออกแล้วครับ"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
