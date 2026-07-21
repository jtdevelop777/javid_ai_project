from std.python import Python, PythonObject
from models import MemoryModel


struct MemoryRepository:
    var db_connection: PythonObject

    def __init__(out self: Self, db_conn: PythonObject):
        self.db_connection = db_conn

    def save(self, model: MemoryModel):
        try:
            var cursor = self.db_connection.cursor()
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
            self.db_connection.commit()
            cursor.close()
            print("💾 [Javid Core] Memory topic registered successfully!")
        except e:
            print("🔴 [Javid Core] Failed to save memory record:", e)
