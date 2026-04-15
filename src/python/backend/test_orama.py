import requests

URL = "http://localhost:11434/api/generate"
response = requests.post(
    URL,
    json={
        "model": "llama3",
        "prompt": "Why is the sky blue?",
        "stream": False,
    },
)
print(response.json()["response"])