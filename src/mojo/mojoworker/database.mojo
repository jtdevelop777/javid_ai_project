from std.python import Python

def log_to_sqlite(cmd: String, status: String, response: String):
    try:
        var sqlite3 = Python.import_module("sqlite3")
        var conn = sqlite3.connect("javid_memory.db")
        var cursor = conn.cursor()
        cursor.execute("CREATE TABLE IF NOT EXISTS javid_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, command TEXT, status TEXT, response TEXT)")
        var params = Python.list()
        params.append(cmd)
        params.append(status)
        params.append(response)
        cursor.execute("INSERT INTO javid_logs (command, status, response) VALUES (?, ?, ?)", params)
        conn.commit()
        conn.close()
    except:
        pass