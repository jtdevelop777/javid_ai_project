import time
import serial
import psutil

# กำหนดค่าพอร์ตและ Baud Rate ให้ตรงกับฝั่งจอเล็ก
PORT = "/dev/ttyUSB0"
BAUD_RATE = 115200  # ถ้าหน้าจอใช้ความเร็วอื่น สามารถปรับแก้ตรงนี้ได้ครับ

print(f"Connecting to GlowCube on {PORT}...")
try:
    ser = serial.Serial(PORT, BAUD_RATE, timeout=1)
    print("Connected successfully! Starting data transmission...")
    
    while True:
        # ดึงค่า CPU และ RAM จากระบบจริง
        cpu_val = psutil.cpu_percent(interval=1)
        ram_val = psutil.virtual_memory().percent
        
        # จัดฟอร์แมตข้อมูลที่จะส่ง (ส่งเป็นข้อความสั้นๆ หรือจะปรับเป็น JSON ก็ได้ครับ)
        # ตัวอย่างส่งแบบ Text: "CPU:xx.x,RAM:xx.x\n"
        payload = f"CPU:{cpu_val:.1f},RAM:{ram_val:.1f}\n"
        
        # ส่งข้อมูลออกพอร์ต Serial
        ser.write(payload.encode('utf-8'))
        print(f"Sent -> {payload.strip()}")
        
        # หน่วงเวลาเล็กน้อยก่อนส่งรอบถัดไป
        time.sleep(1)

except serial.SerialException as e:
    print(f"Serial Error: {e}")
except KeyboardInterrupt:
    print("\nStopping transmission. Goodbye, Captain!")
    if 'ser' in locals() and ser.is_open:
        ser.close()