from std.python import Python, PythonObject


struct TaskModel:
    var id: String
    var command: String
    var status: String
    var response: String
    var attachment_path: String
    var progress: Int
    var estimated_sec: Float64
    # --- New Validation Guard Fields ---
    var auth_key: String  # Key สำหรับด่านตรวจสิทธิ์
    var target_version: String  # เวอร์ชันที่ระบุมากับ Task (เพื่อดักเช็ค Auto Update)

    # Modern Constructor with proper 'out self: Self' typing
    def __init__(out self: Self, cmd: String):
        try:
            var time_mod = Python.import_module("time")
            self.id = "TASK-" + String(time_mod.time())
        except:
            self.id = "TASK-UNKNOWN"

        var final_cmd: String
        var extracted_key: String = ""
        var extracted_version: String = ""

        try:
            var json_mod = Python.import_module("json")
            var parsed_json = json_mod.loads(cmd)

            # --- Extract command as usual
            final_cmd = String(parsed_json["command"])

            # --- Extract verification tokens from JSON payload if present
            if "auth_key" in parsed_json:
                extracted_key = String(parsed_json["auth_key"])
            if "target_version" in parsed_json:
                extracted_version = String(parsed_json["target_version"])
        except:
            final_cmd = cmd

        self.command = final_cmd
        self.auth_key = extracted_key
        self.target_version = extracted_version

        self.status = "PENDING"
        self.response = "-"
        self.attachment_path = "-"
        self.progress = 0
        self.estimated_sec = 5.0 + (Float64(final_cmd.byte_length()) / 10.0)

    def to_json(self, msg_type: String) -> String:
        var c = self.command.replace('"', '\\"').replace("\n", "\\n")
        var r = self.response.replace('"', '\\"').replace("\n", "\\n")
        var a = self.attachment_path.replace('"', '\\"').replace("\\", "\\\\")

        var val_to_send: String
        if msg_type == "answer":
            val_to_send = r
        elif msg_type == "estimation":
            val_to_send = String(self.estimated_sec)
        else:
            val_to_send = String(self.progress)

        # --- Appended auth_key and target_version to the JSON string output
        return (
            '{"type": "'
            + msg_type
            + '", "id": "'
            + self.id
            + '", "progress": '
            + String(self.progress)
            + ', "value": "'
            + val_to_send
            + '"'
            + ', "command": "'
            + c
            + '", "response": "'
            + r
            + '", "attachment_path": "'
            + a
            + '", "auth_key": "'
            + self.auth_key
            + '", "target_version": "'
            + self.target_version
            + '"}'
        )
