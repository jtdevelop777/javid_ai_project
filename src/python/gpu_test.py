import subprocess
import json
import requests

def get_gpu_status():
    # ในกรณีของ AMD เราสามารถดึงค่าจากไฟล์ระบบ หรือใช้ rocm-smi ถ้าติดตั้งไว้
    # แต่เบื้องต้นลองดึงค่าแบบจำลองเพื่อทดสอบ Flow ก่อนครับ
    status = {
        "device": "AMD Radeon RX 470",
        "vram_usage": "3.2GB / 4.0GB",
        "load": "95%",
        "temp": "72C"
    }
    return status

def ask_javid(status_data):
    url = "http://localhost:11434/api/generate"
    prompt = f"System Report: {json.dumps(status_data)}. ในฐานะผู้เชี่ยวชาญ AI คุณคิดว่าสถานะการ์ดจอนี้ปกติไหมสำหรับการรัน LLM? ตอบเป็นภาษาไทยสั้นๆ"
    
    payload = {
        "model": "llama3",
        "prompt": prompt,
        "stream": False
    }
    
    try:
        response = requests.post(url, json=payload)
        return response.json().get("response", "ไม่สามารถติดต่อ Javid ได้")
    except Exception as e:
        return f"Error: {str(e)}"

if __name__ == "__main__":
    print("--- ดึงข้อมูลจาก RX470 ---")
    status = get_gpu_status()
    print(f"สถานะปัจจุบัน: {status}")
    
    print("\n--- กำลังถาม Javid AI ---")
    answer = ask_javid(status)
    print(f"Javid ตอบว่า: {answer}")
