from std.python import Python, PythonObject
from models import MemoryModel


struct MemoryRepository:
    var db_connection: PythonObject

    def __init__(out self: Self, db_conn: PythonObject):
        self.db_connection = db_conn

    def save(self, model: MemoryModel):
        try:
            var sqlite3 = Python.import_module("sqlite3")
            var builtins = Python.import_module("builtins")

            # 💡 ใช้ Direct Connection ไปที่ไฟล์ DB จริงแบบเดียวกับ log_to_sqlite 100%
            var conn = sqlite3.connect(
                "/mnt/javid_data/projects/javid_ai/javid_memory.db"
            )
            var cursor = conn.cursor()

            var query = String(
                "INSERT INTO javid_memories (topic, content, category_id,"
                " priority, metadata) VALUES (?, ?, ?, ?, ?)"
            )

            var json_mod = Python.import_module("json")
            var p_metadata_str = json_mod.dumps(model.metadata)

            var py_args = Python.list()
            py_args.append(PythonObject(model.topic))
            py_args.append(PythonObject(model.content))
            py_args.append(PythonObject(model.category_id))
            py_args.append(PythonObject(model.priority))
            py_args.append(p_metadata_str)

            cursor.execute(query, py_args)
            conn.commit()  # Commit ที่ Connection ตรงนี้เลย
            cursor.close()
            conn.close()

            print(
                "💾 [Javid Core] Memory topic registered & committed directly"
                " successfully!"
            )
        except e:
            print("🔴 [Javid Core] Failed to save memory record:", e)
