import sqlite3
import psycopg2 # สำหรับ PostgreSQL (ถ้าลง library ไว้แล้ว)
from datetime import datetime

# --- CONFIGURATION ---
DB_SQLITE_NAME = 'javid_local_memory.db'

# --- SQL SCHEMA (Master Template) ---
# ยึดหลัก Priority, UserLogin, Timestamp และ CRUD Support
MASTER_SCHEMA = """
CREATE TABLE IF NOT EXISTS javid_logs (
    id SERIAL PRIMARY KEY, 
    ai_tag VARCHAR(20) NOT NULL,
    priority INTEGER DEFAULT 2, -- 0:Critical, 1:High, 2:Normal, 3:Low
    content TEXT NOT NULL,
    metadata JSONB, -- สำหรับเก็บ JSON data เพิ่มเติม
    user_login VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS micro_skills (
    skill_id SERIAL PRIMARY KEY,
    skill_name VARCHAR(100) UNIQUE,
    description TEXT,
    priority INTEGER DEFAULT 2,
    user_login VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"""

def init_sqlite():
    """สร้างฐานข้อมูล SQLite สำหรับเก็บค่า Local Config"""
    try:
        # SQLite ไม่รองรับ SERIAL และ JSONB ตรงๆ ต้องปรับนิดหน่อย
        sqlite_schema = MASTER_SCHEMA.replace("SERIAL PRIMARY KEY", "INTEGER PRIMARY KEY AUTOINCREMENT")
        sqlite_schema = sqlite_schema.replace("JSONB", "TEXT")
        sqlite_schema = sqlite_schema.replace("TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP", "DATETIME DEFAULT CURRENT_TIMESTAMP")
        
        conn = sqlite3.connect(DB_SQLITE_NAME)
        cursor = conn.cursor()
        cursor.executescript(sqlite_schema)
        conn.commit()
        conn.close()
        print(f"✅ [SQLite] Initialize '{DB_SQLITE_NAME}' success!")
    except Exception as e:
        print(f"❌ [SQLite] Error: {e}")

def init_postgres(host, user, password, dbname):
    """สร้างฐานข้อมูล PostgreSQL สำหรับระบบหลัก (ถ้ากัปตันรัน Docker ไว้แล้ว)"""
    try:
        conn = psycopg2.connect(host=host, user=user, password=password, dbname=dbname)
        cursor = conn.cursor()
        cursor.execute(MASTER_SCHEMA)
        conn.commit()
        cursor.close()
        conn.close()
        print(f"✅ [PostgreSQL] Initialize '{dbname}' success!")
    except Exception as e:
        print(f"❌ [PostgreSQL] Connection failed (Check if Docker is running): {e}")

# --- รันคำสั่ง ---
if __name__ == "__main__":
    print(f"--- Javid AI System Database Initialization ---")
    init_sqlite()
    # ถ้ากัปตันจะรัน Postgres ให้ใส่ค่าข้างล่างนี้แล้วเอาคอมเมนต์ออกครับ
    # init_postgres('localhost', 'postgres', 'your_password', 'javid_db')