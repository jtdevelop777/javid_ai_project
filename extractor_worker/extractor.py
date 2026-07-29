import os
import base64
import asyncio
import requests
from playwright.async_api import async_playwright

# กำหนด Path สำหรับเก็บไฟล์ภาพจริงบนไดรฟ์ก้อนใหญ่
STORAGE_IMAGE_DIR = "/mnt/javid_data/projects/javid_ai/storage/images"
os.makedirs(STORAGE_IMAGE_DIR, exist_ok=True)

async def process_and_extract_images(target_url):
    print(" [1/4] กำลังเชื่อมต่อไปยัง Google Chrome (CDP)...")
    async with async_playwright() as p:
        try:
            # เชื่อมต่อผ่านพอร์ต Remote Debugging ของ Chrome
            browser = await p.chromium.connect_over_cdp("http://host.docker.internal:9222")
            context = browser.contexts[0]
            page = context.pages[0] if context.pages else await context.new_page()
            
            print(f" [2/4] เข้าสู่หน้าเว็บ: {target_url}")
            try:
                await page.goto(target_url, wait_until="domcontentloaded", timeout=30000)
            except Exception as nav_err:
                print(f" Navigation warning (ดำเนินการต่อ): {nav_err}")
                
            print(" รอโหลดองค์ประกอบหน้าเว็บ 5 วินาที...")
            await page.wait_for_timeout(5000)
            
            # ค้นหารูปภาพทั้งหมดในหน้าแชต
            img_elements = await page.query_selector_all("img")
            print(f" [3/4] พบรูปภาพบนหน้าเว็บทั้งหมด: {len(img_elements)} รูป")
            
            extracted_assets = []
            saved_count = 0
            
            for idx, img in enumerate(img_elements):
                try:
                    box = await img.bounding_box()
                    if not box or box['width'] < 60 or box['height'] < 60:
                        continue
                        
                    print(f" กำลังดึงภาพ HD รูปที่ {idx + 1}...")
                    await img.scroll_into_view_if_needed()
                    await page.wait_for_timeout(500)
                    await img.click(force=True)
                    await page.wait_for_timeout(1500)
                    
                    # ตั้งชื่อไฟล์และกำหนดพาทปลายทาง
                    filename = f"img_gemini_{idx + 1}_{int(asyncio.get_event_loop().time())}.png"
                    local_file_path = os.path.join(STORAGE_IMAGE_DIR, filename)
                    
                    lightbox_img = await page.query_selector("main img, [role='main'] img, img[src*='blob:']")
                    if lightbox_img and await lightbox_img.is_visible():
                        await lightbox_img.screenshot(path=local_file_path)
                    else:
                        await page.screenshot(path=local_file_path)
                        
                    back_button = await page.query_selector("button[aria-label*='Back'], button[aria-label*='ย้อนกลับ']")
                    if back_button and await back_button.is_visible():
                        await back_button.click()
                    else:
                        await page.keyboard.press("Escape")
                    await page.wait_for_timeout(800)
                    
                    # เก็บข้อมูลโครงสร้าง Asset เตรียมส่งเข้า DB ต่อไป
                    asset_info = {
                        "type": "image",
                        "filename": filename,
                        "path": f"storage/images/{filename}",
                        "mime_type": "image/png",
                        "caption": f"Extracted image {idx + 1} from Gemini chat",
                        "sort_order": saved_count + 1
                    }
                    extracted_assets.append(asset_info)
                    saved_count += 1
                    
                except Exception as e:
                    print(f" รูปที่ {idx + 1} ไม่สามารถดึงภาพ HD ได้: {e}")
                    await page.keyboard.press("Escape")
                    continue
                    
            print(f" [4/4] บันทึกภาพลง Disk สำเร็จทั้งหมด {saved_count} รูป")
            
            # TODO: ส่วนนี้นำข้อมูลข้อความ + รายการ assets เหล่านี้ ยิงเข้า Ingest API ของ Javid MQ ต่อไป
            # payload = {
            #     "topic": "Gemini Export Session",
            #     "content": "เนื้อหาบทสนทนา...",
            #     "category_id": 1,
            #     "priority": 5,
            #     "metadata": {"source": "gemini", "url": target_url},
            #     "assets": extracted_assets
            # }
            # requests.post("http://localhost:8000/ingest/memory", json=payload)
            
        except Exception as err:
            print(f" เกิดข้อผิดพลาดในการเชื่อมต่อ Chrome: {err}")

if __name__ == "__main__":
    TARGET_URL = "https://gemini.google.com/app/e032b96532eefa4"
    asyncio.run(process_and_extract_images(TARGET_URL))
