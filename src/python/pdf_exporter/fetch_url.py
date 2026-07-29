import os
import asyncio
from playwright.async_api import async_playwright
from PIL import Image

async def export_url_to_pdf(target_url, output_pdf_path):
    print(f"🔄 กำลังเปิด URL: {target_url}")
    
    # Path สำหรับพักไฟล์รูปภาพ Temp
    temp_img_path = output_pdf_path.replace(".pdf", "_temp.png")
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            viewport={'width': 1280, 'height': 800},
            device_scale_factor=2 # เพิ่มความคมชัดระดับ HD
        )
        page = await context.new_page()
        
        # โหลดหน้าเว็บ
        await page.goto(target_url, wait_until="networkidle", timeout=90000)
        
        print("⏳ เลื่อนหน้าจอลงเพื่อบังคับเรนเดอร์รูปภาพทั้งหมด...")
        # Scroll ค่อยๆ ลงล่างสุดเพื่อกระตุ้นให้ Lazy Image ทั้งหมดโหลดขึ้นมา
        for _ in range(15):
            await page.mouse.wheel(0, 1000)
            await page.wait_for_timeout(500)
            
        await page.wait_for_timeout(3000) # รอเรนเดอร์ภาพสมบูรณ์
        
        print("📸 กำลัง Capture ภาพหน้าจอทั้งหน้า (Full Page Screenshot)...")
        await page.screenshot(path=temp_img_path, full_page=True)
        await browser.close()

    print("🖼️ กำลังแปลงภาพ Screenshot เป็นไฟล์ PDF...")
    try:
        image = Image.open(temp_img_path)
        if image.mode == 'RGBA':
            image = image.convert('RGB')
            
        image.save(output_pdf_path, "PDF", resolution=100.0)
        print(f"✅ บันทึก PDF พร้อมรูปภาพสมบูรณ์เรียบร้อย: {output_pdf_path}")
    finally:
        if os.path.exists(temp_img_path):
            os.remove(temp_img_path)

if __name__ == "__main__":
    TARGET_URL = "https://share.gemini.google/Q9BFDSDSTDZi"
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_pdf = os.path.join(script_dir, "gemini_share_export_hd.pdf")
    
    asyncio.run(export_url_to_pdf(TARGET_URL, output_pdf))
