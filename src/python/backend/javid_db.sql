cat <<EOF > /mnt/javid_data/projects/javid_ai/src/python/backend/javid_db.sql
-- ==========================================================
-- Project: Javid AI Knowledge Base (Full Master Schema)
-- Description: Integrated schema from javid_db.docx
-- ==========================================================

-- 1. Master Lookup Tables
CREATE TABLE IF NOT EXISTS lookup_category (
    cat_id INT PRIMARY KEY,
    cat_name_en VARCHAR(100),
    cat_name_th VARCHAR(100)
);

-- 2. Core Knowledge Table (รองรับ Metadata JSONB ตาม javid_db.docx)
CREATE TABLE IF NOT EXISTS knowledge_base (
    id SERIAL PRIMARY KEY,
    topic VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    ai_tag VARCHAR(50) UNIQUE,
    category_id INT REFERENCES lookup_category(cat_id),
    priority INT DEFAULT 3, -- 1=Critical, 2=Important, 3=Normal
    metadata JSONB,         -- เก็บ device_id, sensor_type, location
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Staging Area (กักตัวข้อมูล 7 วันก่อนลบอัตโนมัติ)
CREATE TABLE IF NOT EXISTS jgp_temp_staging (
    staging_id SERIAL PRIMARY KEY,
    raw_data JSONB,
    ai_evaluation_note TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days')
);

-- 4. System History
CREATE TABLE IF NOT EXISTS system_history (
    history_id SERIAL PRIMARY KEY,
    action_type VARCHAR(50), 
    related_tag VARCHAR(50),
    action_note TEXT,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Seed Data
INSERT INTO lookup_category (cat_id, cat_name_en, cat_name_th) VALUES 
(1, 'API Development', 'การพัฒนา API'),
(2, 'Database Design', 'การออกแบบฐานข้อมูล'),
(3, 'Hardware/SDR', 'งานฮาร์ดแวร์และ SDR'),
(4, 'AI Training', 'การสอนและปรับแต่ง AI')
ON CONFLICT (cat_id) DO NOTHING;
EOF
