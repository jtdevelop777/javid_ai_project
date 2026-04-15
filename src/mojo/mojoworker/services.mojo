from std.python import Python

def ask_ollama(prompt: String) -> String:
    try:
        var requests = Python.import_module("requests")
        var payload = Python.dict()
        payload["model"] = "llama3"
        payload["prompt"] = prompt
        payload["stream"] = False
        var res = requests.post("http://localhost:11434/api/generate", json=payload)
        return String(res.json()["response"])
    except:
        return "AI Connection Error"