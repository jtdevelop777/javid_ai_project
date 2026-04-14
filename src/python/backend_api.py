import zmq
from fastapi import FastAPI

app = FastAPI()
context = zmq.Context()
# ท่อสำหรับส่งงาน
socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5555")

@app.get("/process")
async def process_ai(prompt: str):
    # ส่งงานเข้าท่อ ZeroMQ
    socket.send_string(prompt)
    # รอรับผลลัพธ์
    answer = socket.recv_string()
    return {"status": "success", "result": answer}