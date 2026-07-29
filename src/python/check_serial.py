import time
import serial
import psutil

PORT = "/dev/ttyUSB0"
BAUD_RATE = 115200

print(f"Opening bidirectional serial on {PORT}...")
try:
    ser = serial.Serial(PORT, BAUD_RATE, timeout=1)
    print("Ready! Listening to screen and replying with system stats...")
    
    while True:
        # ถ้าจอเล็กส่งข้อมูลอะไรมา (เช่น NODATA)
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8', errors='ignore').strip()
            if line:
                print(f"Screen says: {line}")
                
                # ดึงค่าระบบจริง
                cpu_val = psutil.cpu_percent(interval=None)
                ram_val = psutil.virtual_memory().percent
                
                # ส่งค่ากลับไปให้ทันที
                payload = f"CPU:{cpu_val:.1f},RAM:{ram_val:.1f}\n"
                ser.write(payload.encode('utf-8'))
                print(f"Sent back -> {payload.strip()}")
                
        time.sleep(0.05)

except KeyboardInterrupt:
    print("\nStopping script...")
    if 'ser' in locals() and ser.is_open:
        ser.close()