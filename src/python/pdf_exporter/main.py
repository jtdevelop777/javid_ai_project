import asyncio
from pdf_exporter.exporter import WebToPDFExporter

async def run():
    # ใส่ชื่อไฟล์ที่มีเว้นวรรคให้ตรงกับในเครื่อง
    input_file = "/home/user01/Documents/ตั้งค่า Ignore ไฟล์ใน SmartGit - Google Gemini.html"
    output_pdf = "/mnt/javid_data/projects/javid_ai/src/python/pdf_exporter/output_test.pdf"

    exporter = WebToPDFExporter(width=1920)
    await exporter.export(input_file, output_pdf)

if __name__ == "__main__":
    asyncio.run(run())