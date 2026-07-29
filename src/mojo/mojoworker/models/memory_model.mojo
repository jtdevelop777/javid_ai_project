from std.python import Python, PythonObject

struct AssetModel:
    var type: String
    var filename: String
    var path: String
    var mime_type: String
    var caption: String
    var order: Int

    def __init__(
        out self: Self,
        type: String,
        filename: String,
        path: String,
        mime_type: String,
        caption: String,
        order: Int,
    ):
        self.type = type
        self.filename = filename
        self.path = path
        self.mime_type = mime_type
        self.caption = caption
        self.order = order

struct MemoryModel:
    var topic: String
    var content: String
    var category_id: Int
    var priority: Int
    var metadata: PythonObject
    var assets: PythonObject  # รองรับลิสต์ของ assets ที่ส่งเข้ามา

    def __init__(
        out self: Self,
        topic: String,
        content: String,
        category_id: Int,
        priority: Int,
        metadata: PythonObject,
        assets: PythonObject,
    ):
        self.topic = topic
        self.content = content
        self.category_id = category_id
        self.priority = priority
        self.metadata = metadata
        self.assets = assets


# -------------------------------------------------------------
# Authentication Gate (ระบบล็อกบ้านสไตล์ Simple First)
# -------------------------------------------------------------
def verify_access(incoming_key: String) -> Bool:
    """
    เช็กสิทธิ์ก่อนเข้าถึง Endpoint โดยใช้ def เพื่อให้รองรับ PythonObject
    ดึง Key ลับจากสภาพแวดล้อม (OS Environment) มาเทียบตรงๆ
    """
    try:
        os = Python.import_module("os")
        master_key = os.getenv("JAVID_CORE_API_KEY", "javid_local_dev_key_2026")

        if incoming_key == String(master_key):
            return True

        print("Security Alert: Invalid API Key")
        return False
    except e:
        print("Error inside verify_access:", e)
        return False