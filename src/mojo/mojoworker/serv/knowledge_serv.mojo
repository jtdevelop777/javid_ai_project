# knowledge_service.mojo
from std.python import PythonObject

# from models.memory_model import MemoryModel
# from repositories.memory_repo import MemoryRepository


# ระบุ Type ให้ครบทุกตัวครับ
def save_to_knowledge(
    mem_repo: MemoryRepository,
    topic: String,
    content: String,
    category_id: Int,
    priority: Int,
    metadata: PythonObject,
):
    try:
        var memory_data = MemoryModel(
            topic, content, category_id, priority, metadata
        )
        mem_repo.save(memory_data)
    except e:
        print("🔴 Failed to save memory:", e)
