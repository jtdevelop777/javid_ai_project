import zmq
import requests

context = zmq.Context()
receiver = context.socket(zmq.PULL)
receiver.connect("tcp://localhost:5555")

print("Javid AI Worker พร้อมรบ!")

while True:
    task = receiver.recv_json()
    prompt = task['data']
    
    # ยิงไปที่ Ollama API
    res = requests.post("http://localhost:11434/api/generate", 
                        json={"model": "llama3", "prompt": prompt, "stream": False})
    
    print(f"กัปตันครับ AI ตอบว่า: {res.json().get('response')}")