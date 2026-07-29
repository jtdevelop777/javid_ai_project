import time
import serial
import psutil

PORT = "/dev/ttyUSB0"
BAUD_RATE = 115200

# รายการฟอร์แมตที่จะทดสอบวนไปเรื่อยๆ
FORMATS = [
    "CPU:{cpu},RAM:{ram}\n",
    "cpu={cpu}&ram={ram}\n",
    "{cpu},{ram}\n",
    "{{\"cpu\":{cpu},\"ram\":{ram}}}\n",
    "CPU:{cpu:.1f},RAM:{ram:.1f}\n",
    "C:{cpu},R:{ram}\n",
]

print(f"Starting Fuzzing Protocol on {PORT}...")
try:
    ser = serial.Serial(PORT, BAUD_RATE, timeout=1)
    format_index = 0
    
    while True:
        # อ่านข้อความที่จออาจจะส่งกลับมา
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8', errors='ignore').strip()
            if line:
                print(f"Screen says: {line}")
        
        # ดึงค่าระบบ
        cpu_val = psutil.cpu_percent(interval=None)
        ram_val = psutil.virtual_memory().percent
        
        # เลือกฟอร์แมตทดสอบในรอบนี้
        template = FORMATS[format_index]
        payload = template.format(cpu=cpu_val, ram=ram_val)
        
        # ส่งข้อมูลออกไป
        ser.write(payload.encode('utf-8'))
        print(f"[Format {format_index + 1}] Sent -> {payload.strip()}")
        
        # เปลี่ยนฟอร์แมตทุกๆ 3 วินาที
        format_index = (format_index + 1) % len(FORMATS)
        
        time.sleep(3)

except KeyboardInterrupt:
    print("\nStopping Fuzzing test...")
    if 'ser' in locals() and ser.is_open:
        ser.close()