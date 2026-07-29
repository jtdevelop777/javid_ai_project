import os
import base64
import asyncio
from playwright.async_api import async_playwright
from pypdf import PdfWriter, PdfReader

async def fetch_page_with_playwright(target_url, temp_pdf_path):
    print("🔄 [1/4] กำลังเชื่อมต่อไปยัง Google Chrome เพื่อดึงข้อมูลและรูป HD...")
    async with async_playwright() as p:
        browser = await p.chromium.connect_over_cdp("http://127.0.0.1:9222")
        context = browser.contexts[0]
        page = context.pages[0] if context.pages else await context.new_page()
        
        try:
            await page.goto(target_url, wait_until="domcontentloaded", timeout=30000)
        except Exception as e:
            print(f"⚠️ Navigation warning: {e}")
            
        await page.wait_for_timeout(5000)
        
        # จัดการดึงรูป HD แปลง Base64 ตามโค้ดเดิมของพี่
        img_elements = await page.query_selector_all("img")
        print(f"🖼️ พบรูปภาพทั้งหมด: {len(img_elements)} รูป กำลังประมวลผล...")
        
        for idx, img in enumerate(img_elements):
            try:
                box = await img.bounding_box()
                if not box or box['width'] < 60 or box['height'] < 60:
                    continue

                await img.scroll_into_view_if_needed()
                await page.wait_for_timeout(300)
                await img.click(force=True)
                await page.wait_for_timeout(1000)
                
                temp_img_file = f"/tmp/temp_hd_img_{idx}.png"
                lightbox_img = await page.query_selector("main img, [role='main'] img, img[src*='blob:']")
                
                if lightbox_img and await lightbox_img.is_visible():
                    await lightbox_img.screenshot(path=temp_img_file)
                else:
                    await page.screenshot(path=temp_img_file)
                
                back_button = await page.query_selector("button[aria-label*='Back'], button[aria-label*='ย้อนกลับ']")
                if back_button and await back_button.is_visible():
                    await back_button.click()
                else:
                    await page.keyboard.press("Escape")
                
                await page.wait_for_timeout(500)
                
                with open(temp_img_file, "rb") as image_file:
                    encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
                    base64_data_url = f"data:image/png;base64,{encoded_string}"
                
                await page.evaluate("""({img_elem, new_src}) => {
                    img_elem.src = new_src;
                    img_elem.srcset = '';
                    img_elem.style.maxWidth = '100%';
                    img_elem.style.height = 'auto';
                    img_elem.style.display = 'block';
                }""", {"img_elem": img, "new_src": base64_data_url})
                
                if os.path.exists(temp_img_file):
                    os.remove(temp_img_file)
            except Exception:
                await page.keyboard.press("Escape")
                continue

        # พิมพ์ออกเป็น PDF ดิบตั้งต้นก่อน
        print("📄 [2/4] กำลังพิมพ์หน้าเว็บเป็น PDF ชั่วคราว...")
        await page.pdf(
            path=temp_pdf_path,
            format="A4",
            print_background=True,
            margin={"top": "15mm", "bottom": "15mm", "left": "10mm", "right": "10mm"}
        )

def process_with_pypdf(temp_pdf_path, final_pdf_path):
    print("🔧 [3/4] กำลังใช้ pypdf จัดการโครงสร้างไฟล์ PDF ต่อ...")
    reader = PdfReader(temp_pdf_path)
    writer = PdfWriter()
    
    # สามารถใช้ pypdf วนลูปจัดการหน้า หรือเพิ่ม Metadata/รวมไฟล์ ได้ตามต้องการตรงนี้
    for page in reader.pages:
        writer.add_page(page)
        
    with open(final_pdf_path, "wb") as f:
        writer.write(f)
    print(f"🎉 [4/4] บันทึกไฟล์ PDF สมบูรณ์ด้วย pypdf ที่: {final_pdf_path}")

async def main():
    TARGET_URL = "https://gemini.google.com/app/e032b96532eefa4"
    script_dir = os.path.dirname(os.path.abspath(__file__))
    temp_pdf = os.path.join(script_dir, "temp_output.pdf")
    final_pdf = os.path.join(script_dir, "javid_final_pypdf_output.pdf")
    
    await fetch_page_with_playwright(TARGET_URL, temp_pdf)
    process_with_pypdf(temp_pdf, final_pdf)
    
    if os.path.exists(temp_pdf):
        os.remove(temp_pdf)

if __name__ == "__main__":
    asyncio.run(main())