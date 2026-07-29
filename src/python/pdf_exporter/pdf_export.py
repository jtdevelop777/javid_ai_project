import os
import base64
import asyncio
import markdown2
from bs4 import BeautifulSoup
from playwright.async_api import async_playwright

def image_to_base64(img_path):
    """แปลงรูปภาพ local เป็น Base64 เพื่อฝังลงใน HTML โดยตรง (ภาพไม่มีวันหลุด)"""
    if os.path.exists(img_path):
        with open(img_path, "rb") as image_file:
            encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
            ext = os.path.splitext(img_path)[1].replace('.', '')
            return f"data:image/{ext};base64,{encoded_string}"
    return img_path

def convert_md_to_html(md_content, base_dir="."):
    """แปลง Markdown + Code Block + Embed รูปภาพให้อยู่ใน HTML เดียวกัน"""
    # 1. แปลง Markdown เป็น HTML (เปิดใช้ Fenced Code และ Tables)
    html_raw = markdown2.markdown(md_content, extras=["fenced-code-blocks", "tables", "code-friendly"])
    
    soup = BeautifulSoup(html_raw, 'html.parser')
    
    # 2. ค้นหา Tag <img> ทั้งหมด แล้วจัดการ Embed ภาพแบบ Base64
    for img in soup.find_all('img'):
        src = img.get('src', '')
        if src and not src.startswith('http') and not src.startswith('data:'):
            full_img_path = os.path.join(base_dir, src)
            img['src'] = image_to_base64(full_img_path)
            
    # 3. ใส่ CSS Styling สำหรับ PDF ให้สวยงาม (รองรับภาษาไทย และ Code Blocks)
    styled_html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body {{
                font-family: 'Sarabun', 'Tohama', sans-serif;
                margin: 40px;
                line-height: 1.6;
                color: #333;
            }}
            img {{
                max-width: 100%;
                height: auto;
                display: block;
                margin: 15px 0;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.15);
            }}
            pre {{
                background: #1e1e1e;
                color: #d4d4d4;
                padding: 15px;
                border-radius: 6px;
                overflow-x: auto;
                font-family: 'Consolas', 'Courier New', monospace;
            }}
            code {{
                background: #f4f4f4;
                padding: 2px 6px;
                border-radius: 4px;
                color: #d63384;
            }}
            pre code {{
                background: transparent;
                color: inherit;
                padding: 0;
            }}
        </style>
    </head>
    <body>
        {str(soup)}
    </body>
    </html>
    """
    return styled_html

async def export_to_pdf(md_file_path, output_pdf_path):
    """ฟังก์ชันหลักในการแปลงไฟล์เป็น PDF"""
    base_dir = os.path.dirname(md_file_path)
    
    with open(md_file_path, 'r', encoding='utf-8') as f:
        md_content = f.read()
        
    full_html = convert_md_to_html(md_content, base_dir)
    
    # ใช้ Playwright ในการ Render เป็น PDF
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page()
        
        # โหลด HTML Content
        await page.set_content(full_html, wait_until="networkidle")
        
        # สั่ง Export เป็น PDF
        await page.pdf(
            path=output_pdf_path,
            format="A4",
            print_background=True, # ดึงสีพื้นหลังและ Theme Code ติดไปด้วย
            margin={"top": "20mm", "bottom": "20mm", "left": "15mm", "right": "15mm"}
        )
        await browser.close()
        print(f"✅ Export PDF สำเร็จ: {output_pdf_path}")

# --- ตัวอย่างการใช้งาน ---
if __name__ == "__main__":
    # ระบุไฟล์ MD ต้นทาง และไฟล์ PDF ปลายทาง
    asyncio.run(export_to_pdf("src/python/javid_coding_howto.txt", "export_output.pdf"))