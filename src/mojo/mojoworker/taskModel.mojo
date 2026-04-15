from std.python import Python

struct TaskModel:
    var id: String
    var command: String
    var status: String
    var response: String
    var attachment_path: String # <--- เพิ่มไว้เก็บที่อยู่รูปภาพในเครื่อง
    var progress: Int
    var estimated_sec: Float64


    def __init__(out self, cmd: String):
            try:
                var time_mod = Python.import_module("time")
                self.id = "TASK-" + String(time_mod.time())
            except:
                self.id = "TASK-UNKNOWN"
            self.command = cmd
            self.status = "PENDING"
            self.response = "-"
            self.attachment_path = "-"
            self.progress = 0
            
            # --- เปลี่ยนจาก len(cmd) เป็น cmd.byte_length() ---
            self.estimated_sec = 5.0 + (Float64(cmd.byte_length()) / 10.0)        

    def to_json(self, msg_type: String) -> String:
            var c = self.command.replace('"', '\\"').replace('\n', '\\n')
            var r = self.response.replace('"', '\\"').replace('\n', '\\n')
            var a = self.attachment_path.replace('"', '\\"').replace('\\', '\\\\')

            # --- จุดตายอยู่ตรงนี้ครับ ---
            # สร้างตัวแปรไว้เก็บค่าที่จะส่งใน "value"
            var val_to_send: String
            
            if msg_type == "answer":
                val_to_send = r  # ถ้าเป็นคำตอบ ให้ส่งคำตอบ AI ออกไป
            elif msg_type == "estimation":
                val_to_send = String(self.estimated_sec) # ถ้าเป็นเวลา ให้ส่งตัวเลขเวลา
            else:
                val_to_send = String(self.progress) # อื่นๆ ส่ง progress
                
            return '{"type": "' + msg_type + 
                '", "id": "' + self.id + 
                '", "progress": ' + String(self.progress) + 
                ', "value": "' + val_to_send + '"' + # ใส่ฟันหนูครอบ value ไว้ด้วยเพราะเป็น String
                ', "command": "' + c + 
                '", "response": "' + r + '", "attachment_path": "' + a + '"}'  

             