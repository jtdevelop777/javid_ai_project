from std.python import Python


def ask_ollama(prompt: String) -> String:
    try:
        # ใช้ Python เพื่อเรียกใช้งาน Library
        var requests = Python.import_module("requests")
        var payload = Python.dict()

        # ตั้งค่าโมเดล
        payload["model"] = "qwen2"
        payload["prompt"] = prompt
        payload["stream"] = False

        # เพิ่มการดัก Error ของ Network ไว้ใน try block ของ requests
        var res = requests.post(
            "http://localhost:11434/api/generate", json=payload, timeout=30
        )

        # เช็ค Status Code ก่อนจะพยายามดึง json
        if res.status_code != 200:
            return "AI Error: Server returned " + String(res.status_code)

        var json_res = res.json()
        if "response" in json_res:
            return String(json_res["response"])

        return "AI Error: No response field"

    except e:
        # กัปตันสามารถ print(e) ตรงนี้เพื่อดูรายละเอียด Error ได้หากต้องการ Debug
        return "AI Connection Error: " + String(e)
