-- ==========================================================
-- Database: SQLite (Local Machine State)
-- Purpose: Store local settings and hardware status
-- ==========================================================

CREATE TABLE IF NOT EXISTS local_settings (
    setting_key VARCHAR(50) PRIMARY KEY,
    setting_value TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ข้อมูลเบื้องต้นสำหรับเครื่อง Local
INSERT OR IGNORE INTO local_settings (setting_key, setting_value) VALUES 
('device_id', 'ORIN-01'),
('sdr_status', 'standby'),
('last_git_sync', '2026-04-14');

CREATE TABLE IF NOT EXISTS local_logs (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    log_level VARCHAR(10), -- INFO, ERROR, WARN
    message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

