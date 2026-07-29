import os
import asyncio
from playwright.async_api import async_playwright
from fpdf import FPDF

class PDFManual(FPDF):
    def footer(self):
        self.set_y(-15)
        self.set_font("helvetica", "I", 8)
        self.cell(0, 10, f"Page {self.page_no()}", align="C")

async def scrape_and_build_pdf_with_images(target_url, output_pdf_path):
    print("🔄 [1/4] กำลังเชื่อมต่อเบราว์เซอร์เพื่อดึงข้อมูลและรูปภาพ...")
    async with async_playwright() as p:
        browser = await p.chromium.connect_over_cdp("http://127.0.0.1:9222")
        context = browser.contexts[0]
        page = context.pages[0] if context.pages else await context.new_page()
        
        try:
            await page.goto(target_url, wait_until="domcontentloaded", timeout=30000)
        except Exception as e:
            print(f"⚠️ Navigation warning: {e}")
            
        await page.wait_for_timeout(5000)
        
        # ค้นหาองค์ประกอบทั้งหมด (ทั้งข้อความและรูปภาพ) ตามลำดับในหน้าเว็บ
        print("📥 [2/4] กำลังดึงโครงสร้างเนื้อหาและรูปภาพ...")
        
        # ดึง elements หลักที่เป็นข้อความหรือรูปภาพ
        content_items = await page.evaluate("""() => {
            const elements = document.querySelectorAll('message-content, .message-content, user-query, model-response, p, pre, img');
            let items = [];
            elements.forEach((el, index) => {
                if (el.tagName.toLowerCase() === 'img') {
                    // ถ้าเป็นรูปภาพ เช็คขนาดว่าใหญ่พอที่จะเก็บไหม
                    if (el.naturalWidth > 60 && el.naturalHeight > 60) {
                        items.push({ type: 'image', src: el.src, index: index });
                    }
                } else {
                    let text = el.innerText ? el.innerText.trim() : '';
                    if (text) {
                        items.push({ type: 'text', content: text, index: index });
                    }
                }
            });
            return items;
        }""")
        
        print(f"🔍 พบรายการข้อมูลทั้งหมด {len(content_items)} รายการ กำลังประมวลผลรูปภาพ...")
        
        pdf = PDFManual()
        pdf.add_page()
        pdf.set_font("helvetica", "B", 16)
        pdf.cell(0, 10, "Javid AI Project Manual (With Images)", ln=True, align="L")
        pdf.ln(5)
        pdf.set_font("helvetica", "", 10)
        
        temp_img_dir = "/tmp/pdf_images"
        os.makedirs(temp_img_dir, exist_ok=True)
        
        # วนลูปจัดการทีละไอเทม (ข้อความ หรือ รูปภาพ)
        for idx, item in enumerate(content_items):
            try:
                if item['type'] == 'text':
                    clean_text = item['content'].encode('latin-1', 'ignore').decode('latin-1')
                    pdf.multi_cell(0, 6, clean_text)
                    pdf.ln(3)
                elif item['type'] == 'image':
                    # หา element รูปภาพตัวจริงในหน้าเว็บแล้วแคปเจอร์
                    img_elements = await page.query_selector_all("img")
                    # หาตัวที่ตรงกันหรือใช้วิธี screenshot ทีละตัว
                    temp_img_path = os.path.join(temp_img_dir, f"img_{idx}.png")
                    
                    # สั่ง scroll ไปที่รูปและแคปเจอร์
                    img_loc = img_elements[item['index']] if item['index'] < len(img_elements) else None
                    if img_loc:
                        box = await img_loc.bounding_box()
                        if box and box['width'] > 50 and box['height'] > 50:
                            await img_loc.screenshot(path=temp_img_path)
                            pdf.ln(5)
                            # วางรูปลงใน PDF (กำหนดความกว้าง 140 มม. กำลังสวย)
                            pdf.image(temp_img_path, w=140)
                            pdf.ln(5)
            except Exception as ex:
                print(f"⚠️ ข้ามไอเทมที่ {idx} เนื่องจากเกิดข้อผิดพลาด: {ex}")
                continue

        print(f"📄 [3/4] กำลังบันทึกไฟล์ PDF...")
        pdf.output(output_pdf_path)
        print(f"🎉 [4/4] สร้าง Manual พร้อมรูปภาพสำเร็จที่: {output_pdf_path}")

if __name__ == "__main__":
    TARGET_URL = "https://gemini.google.com/app/e032b96532eefa4"
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_pdf = os.path.join(script_dir, "javid_manual_with_images.pdf")
    
    asyncio.run(scrape_and_build_pdf_with_images(TARGET_URL, output_pdf))