# Python: TaskPusher.py
import zmq

def push_to_java():
    context = zmq.Context()
    # ตรวจสอบให้มั่นใจว่าเป็น PUSH
    socket = context.socket(zmq.PUSH) 
    socket.connect("tcp://127.0.0.1:5556")
    
    prompt = "กัปตันจักร์ชัยส่งมาทดสอบระบบคิว: ท้องฟ้าสีอะไร?"
    print(f"📤 กำลังโยนงานลงสายพาน: {prompt}")
    
    socket.send_string(prompt)
    print("✅ โยนงานเสร็จแล้ว! ไปนอนรอผลลัพธ์ได้เลยกัปตัน")
    
    socket.close()
    context.term()

if __name__ == "__main__":
    push_to_java()
