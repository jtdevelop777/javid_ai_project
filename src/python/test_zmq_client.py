# ชื่อไฟล์: test_zmq_client.py (รันด้วย python ได้เลยครับ)
import zmq

context = zmq.Context()
sender = context.socket(zmq.PUSH)
sender.connect("tcp://localhost:5555")

# กัปตันเปลี่ยนข้อความในนี้เพื่อทดสอบได้เลยครับ
msg = "ช่วยวิเคราะห์ระบบหน่อยว่าวันนี้ต้องทำอะไรบ้าง"
sender.send_string(msg)
print("ส่งงานให้ Javid AI แล้ว:", msg)
