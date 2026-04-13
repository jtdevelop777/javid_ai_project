import chromadb
from chromadb.utils import embedding_functions

# 1. เชื่อมต่อ ChromaDB (รันผ่าน Docker ที่พอร์ต 8000 ตามที่เราตั้งไว้)
client = chromadb.HttpClient(host='localhost', port=8000)

# 2. สร้าง Collection สำหรับเก็บ Know-how (เปรียบเสมือน Table ใน SQL)
# ใช้ Sentence Transformer ในการแปลงข้อจำเป็น Vector
knowledge_collection = client.get_or_create_collection(
    name="javid_semantic_memory",
    metadata={"description": "Store AI know-how and meeting summaries"}
)

print("ChromaDB Collection 'javid_semantic_memory' is ready.")

# ตัวอย่าง Schema ของข้อมูลที่จะเก็บ (Metadata)
# {
#   "id": "ai_tag_XXXX",
#   "document": "เนื้อหาการประชุม...",
#   "metadata": {"category": "API", "priority": 2, "author": "Jakchai"}
# }

