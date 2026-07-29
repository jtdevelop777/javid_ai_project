import os
from pathlib import Path
from playwright.async_api import async_playwright

class WebToPDFExporter:
    def __init__(self, width: int = 1920):
        self.width = width

    async def export(self, input_path: str, output_path: str, scroll_delay: int = 100):
        # ปรับการแปลง Path ให้เป็น file:// URL ที่สมบูรณ์เสมอ
        if input_path.startswith("http://") or input_path.startswith("https://"):
            url = input_path
        else:
            # แปลงเป็น absolute path แล้วเติม file://
            file_path = Path(input_path).resolve()
            url = file_path.as_uri()

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            context = await browser.new_context(viewport={"width": self.width, "height": 1080})
            page = await context.new_page()

            print(f"🔄 กำลังโหลด: {url}")
            await page.goto(url, wait_until="networkidle")

            # 1. ปรับแต่ง CSS เพื่อปิด Sticky/Fixed elements
            await page.add_style_tag(content="""
                header, footer, nav, [class*="sticky"], [class*="fixed"] {
                    position: static !important;
                }
                body {
                    background-color: #ffffff !important;
                }
            """)

            # 2. Scroll ลงล่างเพื่อกระตุ้นให้ Lazy-loaded images แสดงผล
            print("📜 กำลัง Scroll โหลดรูปภาพทั้งหมด...")
            await page.evaluate(f"""
                async () => {{
                    await new Promise((resolve) => {{
                        let totalHeight = 0;
                        const distance = 300;
                        const timer = setInterval(() => {{
                            const scrollHeight = document.body.scrollHeight;
                            window.scrollBy(0, distance);
                            totalHeight += distance;
                            if (totalHeight >= scrollHeight) {{
                                clearInterval(timer);
                                window.scrollTo(0, 0);
                                resolve();
                            }}
                        }}, {scroll_delay});
                    }});
                }}
            """)

            await page.wait_for_timeout(1000)

            # 3. คำนวณความสูงจริงของเนื้อหา
            page_height = await page.evaluate("document.body.scrollHeight")
            print(f"📏 ขนาดหน้าเว็บ: {self.width}x{page_height} px")

            # 4. แปลงเป็น PDF แบบยาวต่อเนื่อง
            os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
            await page.pdf(
                path=output_path,
                width=f"{self.width}px",
                height=f"{page_height}px",
                print_background=True,
                margin={"top": "0px", "right": "0px", "bottom": "0px", "left": "0px"}
            )

            await browser.close()
            print(f"✅ บันทึก PDF เรียบร้อย: {output_path}")