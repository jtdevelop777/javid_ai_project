from std.python import Python


# 💡 ปรับให้ฟังก์ชันคืนค่ากลับมาเป็น Int
def log_to_sqlite(
    cmd: String, status: String, response: String, estimate_time: Int
) -> Int:
    try:
        var sqlite3 = Python.import_module("sqlite3")
        var builtins = Python.import_module("builtins")

        var conn = sqlite3.connect(
            "/mnt/javid_data/projects/javid_ai/javid_memory.db"
        )
        var cursor = conn.cursor()

        cursor.execute(
            "CREATE TABLE IF NOT EXISTS javid_logs (id INTEGER PRIMARY KEY"
            " AUTOINCREMENT, command TEXT, status TEXT, response TEXT,"
            " estimate_time INTEGER DEFAULT 0)"
        )

        var params = Python.list()
        params.append(builtins.str(cmd))
        params.append(builtins.str(status))
        params.append(builtins.str(response))
        params.append(builtins.int(estimate_time))

        cursor.execute(
            (
                "INSERT INTO javid_logs (command, status, response,"
                " estimate_time) VALUES (?, ?, ?, ?)"
            ),
            params,
        )

        conn.commit()

        # 💡 ดึงเลข id ที่ SQLite มัน Auto Run สด ๆ ร้อน ๆ ออกมาจาก Cursor
        var last_id_py = cursor.lastrowid
        var last_id = Int(String(builtins.str(last_id_py)))

        cursor.close()
        conn.close()

        print("💾 [Database] Logged with Auto Run ID:", last_id)
        return last_id  # 👈 ยิงเลข ID จริงกลับออกไปให้ระบบหลักใช้ทำงาน!

    except e:
        print("🔴 SQLite Write Exception Occurred!")
        return 0


def get_recent_logs_as_context(limit_count: Int) -> String:
    var context_str = String("")
    try:
        var sqlite3 = Python.import_module("sqlite3")
        var builtins = Python.import_module("builtins")

        var conn = sqlite3.connect(
            "/mnt/javid_data/projects/javid_ai/javid_memory.db"
        )
        var cursor = conn.cursor()

        var params = Python.list()
        params.append(builtins.int(limit_count))

        cursor.execute(
            "SELECT command, response FROM javid_logs ORDER BY id DESC LIMIT ?",
            params,
        )
        var rows = cursor.fetchall()
        var row_count = Int(String(builtins.len(rows)))

        for i in range(row_count):
            var row = rows[i]
            context_str += (
                "Past Command: "
                + String(row[0])
                + " | Past Response: "
                + String(row[1])
                + "\n"
            )

        cursor.close()
        conn.close()
    except e:
        print("🔴 Failed to retrieve hybrid memory context:", e)

    # 💡 จัดเยื้องให้ตรงกับแนว var context_str ให้อยู่ภายใต้ def ฟังก์ชันหลักครับกัปตัน
    return context_str
