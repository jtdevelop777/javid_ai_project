import time
import serial
import psutil

# ตั้งค่าพอร์ต Serial ให้ตรงกับที่ Linux มองเห็น
PORT = "/dev/ttyUSB0"
BAUD_RATE = 115200  # ปรับความเร็วตามสเปกบอร์ด (โดยทั่วไปมักใช้ 115200 หรือ 9600)

try:
    ser = serial.Serial(PORT, BAUD_RATE, timeout=1)
    print(f"Connected to GlowCube on {PORT}")
except Exception as e:
    print(f"Failed to connect to {PORT}: {e}")
    exit(1)

def get_system_stats():
    cpu_usage = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    ram_usage = memory.percent
    return cpu_usage, ram_usage

if __name__ == "__main__":
    try:
        while True:
            cpu, ram = get_system_stats()
            print(f"CPU: {cpu}% | RAM: {ram}%")
            
            # TODO: แพ็คข้อมูลส่งออกพอร์ต serial ไปยังหน้าจอ GlowCube
            # เช่น ser.write(f"CPU:{cpu},RAM:{ram}\n".encode())
            
            time.sleep(2)
    except KeyboardInterrupt:
        ser.close()
        print("\nDisconnected. Safe exit!")