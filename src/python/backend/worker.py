import zmq
import requests

context = zmq.Context()
# ท่อรับงานแบบ PULL (ดึงงานจาก Queue มาทำ)
receiver = context.socket(zmq.PULL)
receiver.connect("tcp://localhost:5555")

print("Javid AI Worker: พร้อมปั่นงานด้วยพลัง RX 470 แล้วครับ!")

while True:
    task = receiver.recv_json()
    prompt = task['prompt']
    
    # ยิงไปหา Ollama (อย่าลืมรันด้วย GFX_VERSION=8.0.3 นะครับกัปตัน)
    try:
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={"model": "llama3", "prompt": prompt, "stream": False},
            timeout=30
        )
        print(f"Javid ตอบกลับ: {response.json().get('response')}")
    except Exception as e:
        print(f"Error: {e}")