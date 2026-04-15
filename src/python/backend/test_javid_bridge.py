import zmq

def test_javid_bridge():
    context = zmq.Context()
    socket = context.socket(zmq.REQ)
    socket.connect("tcp://127.0.0.1:5556")
    
    # ลองส่งภาษาไทยไปเลยครับ ไม่ต้อง native2ascii แล้ว!
    test_prompt = "กัปตันจักร์ชัยถามว่า AI สบายดีไหม?"
    
    print(f"📤 ส่งงานไปที่ Java: {test_prompt}")
    socket.send_string(test_prompt)
    
    # รอรับคำตอบที่ Java ไปคุยกับ Ollama มาให้
    response = socket.recv_string()
    print(f"📥 คำตอบจาก AI (ผ่านท่อ Java): \n{response}")

if __name__ == "__main__":
    test_javid_bridge()
