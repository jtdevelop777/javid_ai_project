from fastapi import FastAPI
import zmq

app = FastAPI()
context = zmq.Context()
# สร้างท่อส่งงาน (Request)
socket = context.socket(zmq.REQ)
socket.bind("tcp://*:5555") # ผูกไว้ที่ Port 5555

@app.get("/ask")
def ask_javid(prompt: str):
    # ส่งงานไปให้ Worker
    socket.send_string(prompt)
    # รอรับคำตอบ
    answer = socket.recv_string()
    return {"reply": answer}