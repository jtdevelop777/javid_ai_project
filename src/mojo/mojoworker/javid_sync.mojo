from std.python import Python
from std.time import sleep
from mojoworker.utils.javid_config import JavidConfig


def main() raises:
    var py = Python.import_module("builtins")
    var requests = Python.import_module("requests")
    var time = Python.import_module("time")

    # อิมพอร์ต Playwright ผ่าน Python Interop
    var pw_module = Python.import_module("playwright.sync_api")
    var pw_sync = pw_module.sync_playwright().start()

    var config = JavidConfig()

    # เชื่อมต่อกับ Browser ที่เปิดดีบักทิ้งไว้ (ใช้ Remote Debugging Port จาก Config)
    var browser = pw_sync.chromium.connect_over_cdp(
        config.get("playwright_cdp")
    )
    var context = browser.contexts[0]
    var page = context.pages[0]

    print("🛰️ Connected to Gemini Web: กำลังเฝ้าดู Know-how ใหม่ๆ...")

    var last_content = ""

    while True:
        try:
            # ดึงข้อความล่าสุดจาก Element ของ Gemini
            var current_content = py.str(
                page.query_selector_all(".model-response-text")[-1].inner_text()
            )

            if current_content != last_content:
                print("🆕 พบข้อมูลใหม่! กำลังยิงเข้า Local Javid...")

                var payload = py.dict()
                payload["id"] = "SYNC-" + py.str(time.time())
                payload["command"] = "AUTO_SYNC_KNOW_HOW"
                payload["status"] = "RAW"
                payload["response"] = current_content
                payload["attachment_path"] = "-"

                # แก้ไข URL ให้ถูกต้อง (เอาตัว l ที่เกินออก)
                var r = requests.post(
                    "http://192.168.4.9:8001/ingest", json=payload, timeout=10
                )
                if r.status_code == 200:
                    print("✅ Sync สำเร็จ: ข้อมูลลงบ่อพัก SQLite เรียบร้อย")
                    last_content = current_content
                else:
                    print("⚠️ Server ตอบกลับด้วยสถานะ: ", r.status_code)
        except e:
            print("⚠️ ติดปัญหาในการดึงข้อมูลหรือเชื่อมต่อ: ", e)

        time.sleep(5)  # พัก 5 วินาทีแล้วเช็คใหม่


def sync_to_javid(content: String, file_path: String = "-"):
    try:
        var py = Python.import_module("builtins")
        var requests = Python.import_module("requests")
        var time_mod = Python.import_module("time")

        var payload = py.dict()
        payload["id"] = "SYNC-" + py.str(time_mod.time())
        payload["command"] = "AUTO_SYNC_KNOW_HOW"
        payload["status"] = "RAW"
        payload["response"] = content
        payload["attachment_path"] = file_path
        payload["progress"] = 100
        payload["estimated_sec"] = 0.0

        var url = "http://192.168.4.9:8001/ingest"
        var r = requests.post(url, json=payload, timeout=10)

        if r.status_code == 200:
            print("✅ [FastTrack] โกยข้อมูลเข้าบ่อพักสำเร็จ!")
        else:
            print("❌ เกิดข้อผิดพลาด: ", r.status_code)

    except e:
        print("❌ Error ในการ Sync: ", e)
