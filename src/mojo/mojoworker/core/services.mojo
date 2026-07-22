from std.python import Python


def ask_ollama_cli(prompt: String) -> String:
    try:
        var subprocess = Python.import_module("subprocess")

        # สร้าง Python List แทน List ของ Mojo เพื่อให้ส่งเข้า subprocess ได้ถูกต้อง
        var cmd = Python.list()
        cmd.append("ollama")
        cmd.append("run")
        cmd.append("qwen2")
        cmd.append(prompt)

        var result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            encoding="utf-8"
            # เอา timeout=60 ออกไปเลยครับ
        )

        if result.returncode == 0:
            return String(String(result.stdout).strip())
        else:
            return "CLI Error: " + String(String(result.stderr).strip())

    except e:
        return "Execution Error: " + String(e)


def ask_ollama(prompt: String) -> String:
    try:
        # ใช้ Python เพื่อเรียกใช้งาน Library
        var requests = Python.import_module("requests")
        var payload = Python.dict()

        # ตั้งค่าโมเดล
        payload["model"] = "qwen2"
        payload["prompt"] = prompt
        payload["stream"] = False

        # เพิ่ม Headers บังคับไม่ให้ใช้แคชเก่า
        var headers = Python.dict()
        headers["Cache-Control"] = "no-cache"
        headers["Pragma"] = "no-cache"

        # เปลี่ยน URL มาที่ localhost / 127.0.0.1 และแนบ headers เข้าไป
        var res = requests.post(
            "http://192.168.4.9:11434/api/generate",
            json=payload,
            headers=headers,
            timeout=30,
        )

        # เช็ค Status Code ก่อนจะพยายามดึง json
        if res.status_code != 200:
            return "AI Error: Server returned " + String(res.status_code)

        var json_res = res.json()
        if "response" in json_res:
            return String(json_res["response"])

        return "AI Error: No response field"

    except e:
        return "AI Connection Error: " + String(e)
