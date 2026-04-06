FROM python:3.10-slim

# ติดตั้ง build-essential เพราะ ChromaDB ต้องใช้ตอนลง library บางตัว (C++ layer)
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# ติดตั้ง ChromaDB
RUN pip install chromadb

# กำหนด Path เก็บข้อมูลใน Container
VOLUME /data

# เปิด Port 8000 สำหรับคุยกับ Backend
EXPOSE 8000

CMD ["chroma", "run", "--host", "0.0.0.0", "--port", "8000", "--path", "/data"]
