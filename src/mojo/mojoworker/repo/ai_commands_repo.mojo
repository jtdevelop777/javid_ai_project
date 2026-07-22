from std.python import Python, PythonObject
from core.javid_logger import JavidLogger


struct CommandRepository:
    var db_conn: PythonObject

    def __init__(out self: Self, db_conn: PythonObject) raises:
        var logger_AI = JavidLogger()
        self.db_conn = db_conn
        try:
            logger_AI.info("db_conn:" + String(Python.str(db_conn)))
        except e:
            logger_AI.error(
                "🔴 [CommandRepository] __init__ failed: " + String(e)
            )

    def update_status(self, id: Int, new_status: String) raises:
        var logger_AI = JavidLogger()
        try:
            var sqlite3 = Python.import_module("sqlite3")
            var builtins = Python.import_module("builtins")

            # 💡 ใช้โมเดลเปิดท่อตรงเข้า Absolute Path แบบเดียวกับฟังก์ชันของกัปตันเลยครับ!
            var conn = sqlite3.connect(
                "/mnt/javid_data/projects/javid_ai/javid_memory.db"
            )
            var cursor = conn.cursor()

            var query = String("UPDATE javid_logs SET status = ? WHERE id = ?")

            var params = Python.list()
            params.append(builtins.str(new_status))
            params.append(builtins.int(id))

            # ยิงคำสั่งตรงท่อระบุเป้าหมายชัดเจน
            var _ = cursor.execute(query, params)
            var affected_rows = String(Python.str(cursor.rowcount))

            conn.commit()

            logger_AI.info(
                "📊 SQL Update Result -> Affected Rows: " + affected_rows
            )

            cursor.close()
            conn.close()

        except e:
            logger_AI.error(
                "🔴 [CommandRepository] Update status failed: " + String(e)
            )
