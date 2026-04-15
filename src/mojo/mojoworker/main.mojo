from std.python import Python
from taskModel import TaskModel
import services
import database

def main() raises:
    var zmq = Python.import_module("zmq")
    var context = zmq.Context()
    var receiver = context.socket(zmq.PULL)
    receiver.bind("tcp://*:5555")
    var publisher = context.socket(zmq.PUB)
    publisher.bind("tcp://*:8002")
    
    print("🚀 Javid MQ System: Modular Baseline [COMPLETING...]")
    
    while True:
        var raw_msg = receiver.recv_string()
        var task = TaskModel(String(raw_msg)) 
        
        # ส่งสถานะเริ่มงาน
        publisher.send_string(task.to_json("estimation")) 
        print("⏳ ส่งเวลาประเมิน: " + String(task.estimated_sec) + " วินาที")        

        if "พักผ่อน" in task.command:
            task.response = "สรุปงาน: ระบบ Modular เสร็จสมบูรณ์ทุกไฟล์ [ai_tag: 15042026_0045]"
            database.log_to_sqlite(task.command, "COMPLETED", task.response)
            publisher.send_string(task.to_json("answer"))
            print("💤 ภารกิจจบสิ้น พักผ่อนได้ครับกัปตัน!")
            break
        else:
            # ใช้บริการจากไฟล์ย่อย
            task.response = services.ask_ollama(task.command)
            database.log_to_sqlite(task.command, "COMPLETED", task.response)
            publisher.send_string(task.to_json("answer"))
            print("✨ งานเรียบร้อย")

    


            