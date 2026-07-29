import sqlite3
import os

DB_PATH = "/app/storage/local_cache.db"

def init_local_db():
    # ตรวจสอบและสร้างโฟลเดอร์ storage หากยังไม่มี
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # สร้างตาราง memories (SQLite Syntax)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS memories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            topic TEXT NOT NULL,
            content TEXT,
            category_id INTEGER,
            priority INTEGER DEFAULT 5,
            source_url TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # สร้างตาราง assets (SQLite Syntax)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS assets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            memory_id INTEGER,
            file_type TEXT NOT NULL,
            filename TEXT NOT NULL,
            storage_path TEXT NOT NULL,
            mime_type TEXT,
            caption TEXT,
            sort_order INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (memory_id) REFERENCES memories(id) ON DELETE CASCADE
        )
    """)
    
    conn.commit()
    conn.close()
    print(" SQLite Local Database initialized successfully!")

if __name__ == "__main__":
    init_local_db()