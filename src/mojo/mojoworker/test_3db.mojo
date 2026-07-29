from std.python import Python

def main() raises:
    var py = Python.import_module("builtins")
    var os = Python.import_module("os")
    
    # แก้ปัญหา protobuf ของ ChromaDB
    os.environ["PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"] = "python"
    
    print("=== กำลังทดสอบ Database Drivers ทั้ง 3 ตัวโดยตรงจาก Mojo ===")
    
    # 1. ทดสอบ SQLite (ตรวจสอบและสร้างโฟลเดอร์ storage ถ้ายังไม่มี)
    try:
        var sqlite3 = Python.import_module("sqlite3")
        os.makedirs("../../storage", exist_ok=True)
        var conn_sqlite = sqlite3.connect("../../storage/javid_memory.db")
        print("[OK] SQLite Driver: เชื่อมต่อสำเร็จ (storage/javid_memory.db)")
        conn_sqlite.close()
    except e:
        print("[ERROR] SQLite Driver ล้มเหลว:", e)

    # 2. ทดสอบ ChromaDB
    try:
        var chromadb = Python.import_module("chromadb")
        var client_chroma = chromadb.PersistentClient(path="../../storage/chroma")
        print("[OK] ChromaDB Driver: เชื่อมต่อ/โหลด Client สำเร็จ")
    except e:
        print("[ERROR] ChromaDB Driver ล้มเหลว:", e)

    # 3. ทดสอบ PostgreSQL
    try:
        var psycopg2 = Python.import_module("psycopg2")
        print("[OK] PostgreSQL Driver (psycopg2): โหลดโมดูลสำเร็จ พร้อมเชื่อมต่อ")
    except e:
        print("[ERROR] PostgreSQL Driver ล้มเหลว:", e)