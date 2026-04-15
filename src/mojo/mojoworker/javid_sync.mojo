from std.python import Python
# from python import Python
import time

def main() raises:
    var py = Python.import_module("builtins")
    var requests = Python.import_module("requests")
    var time = Python.import_module("time")
    
    # หมายเหตุ: ใน Mojo เราจะใช้ Python library สำหรับการทำ Web Automation (เช่น Playwright) 
    # เพื่อดึงข้อมูลจาก Browser ที่กัปตันเปิดอยู่
    var playwright = Python.import_module("playwright.sync_api").sync_playwright()
    
    print("🚀 Javid Sync: เริ่มต้นระบบดูดข้อมูลสาย Hardcore...")
    
    with playwright as pw:
        # เชื่อมต่อกับ Browser ที่กัปตันเปิดทิ้งไว้ (ใช้ Remote Debugging Port)
        var browser = pw.chromium.connect_over_cdp("http://localhost:9222")
        var context = browser.contexts[0]
        var page = context.pages[0]

        print("📡 Connected to Gemini Web: กำลังเฝ้าดู Know-how ใหม่ๆ...")

        var last_content = ""

        while True:
            # ดึงข้อความล่าสุดจาก Element ของ Gemini
            # (Selector นี้ต้องปรับตามโครงสร้างหน้าเว็บจริง)
            var current_content = py.str(page.query_selector_all(".model-response-text")[-1].inner_text())

            if current_content != last_content:
                print("🆕 พบข้อมูลใหม่! กำลังยิงเข้า Local Javid...")
                
                # ยิง JSON เข้า API 8001 ของเรา
                # --- ปรับ Payload ให้ตรงกับ TaskModel ที่เราออกแบบไว้ ---
                var payload = py.dict()
                payload["id"] = "SYNC-" + py.str(time.time()) # สร้าง ID ไม่ให้ซ้ำ
                payload["command"] = "AUTO_SYNC_KNOW_HOW"
                payload["status"] = "RAW"
                payload["response"] = current_content # เนื้อหาจาก Gemini
                payload["attachment_path"] = "-" # เผื่อไว้ใส่ Path รูปในอนาคต

                try:
                    # --- เปลี่ยนจาก /task เป็น /ingest (เลนด่วน) ---
                    var r = requests.post("http://localhost:8001/ingest", json=payload)
                    if r.status_code == 200:
                        print("✅ Sync สำเร็จ: ข้อมูลลงบ่อพัก SQLite เรียบร้อย")
                        last_content = current_content
                except:
                    print("⚠️ ติดปัญหาการเชื่อมต่อกับ API 8001")

            time.sleep(5) # พัก 5 วินาทีแล้วเช็คใหม่ (ประหยัด CPU)



def sync_to_javid(content: String, file_path: String = "-"):
    try:
        var py = Python.import_module("builtins")
        var requests = Python.import_module("requests")
        var time_mod = Python.import_module("time")

        # สร้าง Payload ให้ตรงกับ TaskModel (Native Struct)
        var payload = py.dict()
        payload["id"] = "SYNC-" + py.str(time_mod.time())
        payload["command"] = "AUTO_SYNC_KNOW_HOW"
        payload["status"] = "RAW"          # สถานะรอคัดกรอง
        payload["response"] = content     # เนื้อหา Know-how
        payload["attachment_path"] = file_path # เก็บ Path รูปหรือไฟล์อื่นๆ
        payload["progress"] = 100
        payload["estimated_sec"] = 0.0

        # ยิงเข้าเลนด่วน (Bypass) Port 8001
        var url = "http://localhost:8001/ingest"
        var r = requests.post(url, json=payload)
        
        if r.status_code == 200:
            print("✅ [FastTrack] โกยข้อมูลเข้าบ่อพักสำเร็จ!")
        else:
            print("❌ เกิดข้อผิดพลาด: ", r.status_code)

    except e:
        print("❌ Error ในการ Sync: ", e)

# --- ตัวอย่างการเรียกใช้ ---
# sync_to_javid("เนื้อหาที่ดูดมา...", "/mnt/javid_data/attachments/manual.pdf")            