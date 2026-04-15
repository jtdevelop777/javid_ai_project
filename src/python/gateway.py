from fastapi import FastAPI
import zmq

app = FastAPI()
context = zmq.Context()
# ใช้ PUSH เพื่อส่งงานลง Queue
sender = context.socket(zmq.PUSH)
sender.bind("tcp://*:5555")

@app.get("/javid/ask")
async def ask(prompt: str):
    sender.send_json({"data": prompt})
    return {"status": "งานส่งเข้าคิวแล้วครับกัปตัน!"}