import os
import base64
import asyncio
from playwright.async_api import async_playwright
from weasyprint import HTML, CSS

async def extract_chat_content(target_url):
    print(" [1/4] กำลังเชื่อมต่อไปยัง Google Chrome เพื่อดึงข้อมูลแชตและแปลงรูปภาพ...")
    async with async_playwright() as p:
        browser = await p.chromium.connect_over_cdp("http://127.0.0.1:9222")
        context = browser.contexts[0]
        page = context.pages[0] if context.pages else await context.new_page()
        
        try:
            await page.goto(target_url, wait_until="domcontentloaded", timeout=60000)
        except Exception as e:
            print(f" โหลดหน้าเว็บช้ากำลังลองรีเฟรช: {e}")
            await page.reload(wait_until="domcontentloaded", timeout=60000)
            
        await page.wait_for_timeout(5000)
        
        # เลื่อนหน้าจอเพื่อกระตุ้นให้รูปโหลดครบ
        await page.evaluate("window.scrollTo(0, document.body.scrollHeight);")
        await page.wait_for_timeout(3000)
        await page.evaluate("window.scrollTo(0, 0);")
        await page.wait_for_timeout(2000)
        
        # แปลงรูปภาพทั้งหมดในแชตเป็น Base64
        print(" กำลังแปลงรูปภาพในหน้าแชตเป็น Base64...")
        await page.evaluate("""async () => {
            const images = document.querySelectorAll('message-content img, .message-content img, user-query img, model-response img, img');
            for (let img of images) {
                let src = img.src;
                if (!src || src.startsWith('data:image') || src.includes('preview') || src.includes('placeholder')) continue;
                try {
                    let response = await fetch(src);
                    let blob = await response.blob();
                    await new Promise((resolve) => {
                        let reader = new FileReader();
                        reader.onloadend = () => {
                            img.src = reader.result;
                            img.removeAttribute('srcset');
                            resolve();
                        };
                        reader.readAsDataURL(blob);
                    });
                } catch (err) {
                    console.log('Skipping image due to fetch error');
                }
            }
        }""")
        
        await page.wait_for_timeout(3000)
        
        # ดึงเฉพาะบล็อกข้อความบทสนทนามาประกอบร่าง
        chat_html = await page.evaluate("""() => {
            const messages = document.querySelectorAll('message-content, .message-content, user-query, model-response');
            if (messages.length > 0) {
                let combinedHTML = '';
                messages.forEach(msg => {
                    const clone = msg.cloneNode(true);
                    clone.querySelectorAll('.avatar, .user-icon').forEach(el => el.remove());
                    combinedHTML += clone.outerHTML + '<hr style="margin: 20px 0; border: 0; border-top: 1px solid #ccc;">';
                });
                return combinedHTML;
            }
            return document.body.innerHTML;
        }""")
        return chat_html

def generate_pdf_with_weasyprint(chat_html, output_pdf_path):
    print(" [2/4] กำลังจัดรูปแบบ HTML และฉีด Custom CSS สำหรับ WeasyPrint...")
    styled_html = f"""
    <!DOCTYPE html>
    <html lang="th">
    <head>
    <meta charset="UTF-8">
    <style>
        @page {{
            size: A4;
            margin: 20mm 15mm 20mm 15mm;
            @bottom-right {{
                content: "หน้า " counter(page) " จาก " counter(pages);
                font-size: 10pt;
                font-family: sans-serif;
                color: #666;
            }}
        }}
        body {{
            font-family: 'Sarabun', 'Helvetica Neue', Arial, sans-serif;
            font-size: 11pt;
            line-height: 1.6;
            color: #222;
            background-color: #fff;
        }}
        img {{
            max-width: 100% !important;
            width: 100% !important;
            height: auto !important;
            max-height: none !important;
            object-fit: contain !important;
            display: block !important;
            margin: 20px auto !important;
            border-radius: 8px !important;
            box-shadow: 0 4px 10px rgba(0,0,0,0.15);
        }}
        pre, code {{
            font-family: 'Courier New', Courier, monospace;
            background-color: #1e1e1e;
            color: #dcdcdc;
            padding: 10px;
            border-radius: 6px;
            display: block;
            white-space: pre-wrap;
            word-wrap: break-word;
        }}
        h1, h2, h3 {{
            color: #1a73e8;
            margin-top: 20px;
        }}
        .content-container {{
            width: 100% !important;
            max-width: 100% !important;
        }}
    </style>
    </head>
    <body>
    <div class="content-container">
        {chat_html}
    </div>
    </body>
    </html>
    """
    print(" [3/4] กำลังเรนเดอร์ PDF ด้วย WeasyPrint...")
    HTML(string=styled_html).write_pdf(output_pdf_path)
    print(f" [4/4] สร้าง PDF สำเร็จเรียบร้อยที่: {output_pdf_path}")

async def main():
    TARGET_URL = "https://gemini.google.com/app/7f9031bc711dddc8"
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_pdf = os.path.join(script_dir, "javid_manual_weasyprint.pdf")
    
    chat_html = await extract_chat_content(TARGET_URL)
    generate_pdf_with_weasyprint(chat_html, output_pdf)

if __name__ == "__main__":
    asyncio.run(main())