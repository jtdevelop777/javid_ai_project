import os
import base64
import asyncio
from playwright.async_api import async_playwright

async def process_and_extract_images(target_url):
    print("🔄 [1/4] กำลังเชื่อมต่อไปยัง Google Chrome...")
    
    async with async_playwright() as p:
        try:
            browser = await p.chromium.connect_over_cdp("http://127.0.0.1:9222")
            context = browser.contexts[0]
            page = context.pages[0] if context.pages else await context.new_page()
            
            print(f"🌐 [2/4] เข้าสู่หน้าเว็บ: {target_url}")
            try:
                await page.goto(target_url, wait_until="domcontentloaded", timeout=30000)
            except Exception as nav_err:
                print(f"⚠️ Navigation warning (ดำเนินการต่อ): {nav_err}")
                
            print("⏳ รอโหลดองค์ประกอบหน้าเว็บ 5 วินาที...")
            await page.wait_for_timeout(5000)
            
            # ค้นหารูปภาพทั้งหมดในหน้าแชต
            img_elements = await page.query_selector_all("img")
            print(f"🖼️ [3/4] พบรูปภาพบนหน้าเว็บทั้งหมด: {len(img_elements)} รูป")
            
            replaced_count = 0
            for idx, img in enumerate(img_elements):
                try:
                    box = await img.bounding_box()
                    if not box or box['width'] < 60 or box['height'] < 60:
                        continue

                    print(f"📸 กำลังจัดการรูปภาพ HD รูปที่ {idx + 1}...")
                    await img.scroll_into_view_if_needed()
                    await page.wait_for_timeout(500)
                    
                    await img.click(force=True)
                    await page.wait_for_timeout(1500)
                    
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
                    
                    await page.wait_for_timeout(800)
                    
                    with open(temp_img_file, "rb") as image_file:
                        encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
                        base64_data_url = f"data:image/png;base64,{encoded_string}"
                    
                    await page.evaluate("""({img_elem, new_src}) => {
                        img_elem.src = new_src;
                        img_elem.srcset = '';
                        img_elem.style.maxWidth = '100%';
                        img_elem.style.height = 'auto';
                        img_elem.style.display = 'block';
                        img_elem.style.borderRadius = '8px';
                    }""", {"img_elem": img, "new_src": base64_data_url})
                    
                    replaced_count += 1
                    if os.path.exists(temp_img_file):
                        os.remove(temp_img_file)
                        
                except Exception as e:
                    print(f"⚠️ รูปที่ {idx + 1} ไม่สามารถดึงภาพ HD ได้: {e}")
                    await page.keyboard.press("Escape")
                    continue

            print(f"🔄 [4/4] แทนที่ Thumbnail ด้วยภาพ HD เรียบร้อยทั้งหมด {replaced_count} รูป")
            
            # ฉีด CSS ปรับ Layout ขยายบล็อกและรูปภาพให้เต็มความกว้าง
            print("🎨 กำลังฉีด CSS ปรับ Layout รูปภาพฝั่ง User ให้ขยายกว้างเต็มหน้า...")
            css_content = """
            .user-query, user-query, 
            div[class*="user-query"], 
            div[class*="request-container"] {
                display: block !important;
                width: 100% !important;
                max-width: 100% !important;
            }

            img {
                max-width: 100% !important;
                width: 100% !important;
                height: auto !important;
                display: block !important;
                margin: 20px auto !important;
                border-radius: 8px !important;
                object-fit: contain !important;
            }

            img[width="32"], img[height="32"], img[width="24"], img[height="24"],
            .user-icon img, .avatar img {
                width: auto !important;
                display: inline-block !important;
                margin: 0 !important;
            }
            """
            await page.add_style_tag(content=css_content)
            await page.wait_for_timeout(1000)
            
            print("🎉 ดึงข้อมูลและแปลงรูปภาพ HD สำเร็จพร้อมใช้งานแล้วครับ!")
            
        except Exception as err:
            print(f"❌ เกิดข้อผิดพลาดในการเชื่อมต่อ Chrome: {err}")

if __name__ == "__main__":
    TARGET_URL = "https://gemini.google.com/app/e032b96532eefa4"
    asyncio.run(process_and_extract_images(TARGET_URL))