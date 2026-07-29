from std.python import Python, PythonObject


struct MemoryModel:
    var topic: String
    var content: String
    var category_id: Int
    var priority: Int
    var metadata: PythonObject

    def __init__(
        out self: Self,
        topic: String,
        content: String,
        category_id: Int,
        priority: Int,
        metadata: PythonObject,
    ):
        self.topic = topic
        self.content = content
        self.category_id = category_id
        self.priority = priority
        self.metadata = metadata


# -------------------------------------------------------------
# Authentication Gate (ระบบล็อกบ้านสไตล์ Simple First)
# -------------------------------------------------------------
def verify_access(incoming_key: String) -> Bool:
    """
    เช็กสิทธิ์ก่อนเข้าถึง Endpoint โดยใช้ def เพื่อให้รองรับ PythonObject
    ดึง Key ลับจากสภาพแวดล้อม (OS Environment) มาเทียบตรงๆ
    """
    try:
        # ใน def ห้ามใช้ let หรือ var นำหน้าตัวแปร
        os = Python.import_module("os")
        master_key = os.getenv("JAVID_CORE_API_KEY", "javid_local_dev_key_2026")

        if incoming_key == String(master_key):
            return True

        print("Security Alert: Invalid API Key")
        return False
    except e:
        print("Error inside verify_access:", e)
        return False
