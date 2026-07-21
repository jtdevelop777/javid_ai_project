from std.python import Python, PythonObject


# เติม raises เข้าไปเพื่อให้ Compiler รู้ว่าฟังก์ชันนี้มีโอกาสเกิด Exception
def get_relevant_context(query: String) raises -> PythonObject:
    try:
        var sqlite = Python.import_module("sqlite3")
        var conn = sqlite.connect("javid_data.db")
        var cursor = conn.cursor()

        var params = Python.evaluate("('" + "%" + query + "%" + "',)")
        cursor.execute(
            "SELECT content FROM memories WHERE topic LIKE ?", params
        )

        var results = cursor.fetchall()
        conn.close()
        return results
    except:
        print("⚠️ [Retrieval Service] Error accessing database.")
        return Python.evaluate("[]")
