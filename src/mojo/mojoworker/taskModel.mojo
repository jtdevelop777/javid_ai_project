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
                
            # --- แก้ไขจุดนี้: ประกาศ Type ไว้ก่อนเพื่อเคลียร์ Warning ตัวแปรไม่ได้ใช้งาน ---
            var final_cmd: String
            try:
                var json_mod = Python.import_module("json")
                var parsed_json = json_mod.loads(cmd)
                final_cmd = String(parsed_json["command"])
            except:
                final_cmd = cmd

            self.command = final_cmd
            self.status = "PENDING"
            self.response = "-"
            self.attachment_path = "-"
            self.progress = 0
            
            # --- เปลี่ยนจาก len(cmd) เป็น cmd.byte_length() ---
            self.estimated_sec = 5.0 + (Float64(final_cmd.byte_length()) / 10.0)        

    def to_json(self, msg_type: String) -> String:
            var c = self.command.replace('"', '\\"').replace('\n', '\\n')
            var r = self.response.replace('"', '\\"').replace('\n', '\\n')
            var a = self.attachment_path.replace('"', '\\"').replace('\\', '\\\\')

            # สร้างตัวแปรไว้เก็บค่าที่จะส่งใน "value"
            var val_to_send: String
            
            if msg_type == "answer":
                val_to_send = r  
            elif msg_type == "estimation":
                val_to_send = String(self.estimated_sec) 
            else:
                val_to_send = String(self.progress) 
                
            return '{"type": "' + msg_type + \
                '", "id": "' + self.id + \
                '", "progress": ' + String(self.progress) + \
                ', "value": "' + val_to_send + '"' + \
                ', "command": "' + c + \
                '", "response": "' + r + '", "attachment_path": "' + a + '"}'