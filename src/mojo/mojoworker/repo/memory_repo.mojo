from std.python import Python, PythonObject
from models import MemoryModel


struct MemoryRepository:
    var db_connection: PythonObject

    def __init__(out self: Self, db_conn: PythonObject) raises:
        self.db_connection = db_conn

    def save(self, model: MemoryModel) raises:
            try:
                var psycopg2 = Python.import_module("psycopg2")
                var json_mod = Python.import_module("json")
                var builtins = Python.import_module("builtins")

                # 1. อ่าน Config จากไฟล์ config.json โดยตรง
                var f = builtins.open("config.json", "r")
                var config = json_mod.load(f)
                f.close()

                var db_host = config["db_host"]
                var db_name = config["db_name"]
                var db_user = config["db_user"]
                var db_password = config["db_password"]

                # 2. เชื่อมต่อฐานข้อมูล
                var conn = psycopg2.connect(
                    host=db_host,
                    database=db_name,
                    user=db_user,
                    password=db_password
                )
                
                var cursor = conn.cursor()

                # 1. บันทึกข้อมูลหลักลงตาราง memories ใน PostgreSQL
                var query = String(
                    "INSERT INTO memories (topic, content, category_id, priority, metadata) "
                    "VALUES (%s, %s, %s, %s, %s) RETURNING id"
                )

                var p_metadata_str = json_mod.dumps(model.metadata)

                var py_args = Python.list()
                py_args.append(PythonObject(model.topic))
                py_args.append(PythonObject(model.content))
                py_args.append(PythonObject(model.category_id))
                py_args.append(PythonObject(model.priority))
                py_args.append(p_metadata_str)

                cursor.execute(query, py_args)
                
                var row = cursor.fetchone()
                var memory_id = row[0]

                # 2. วนลูปบันทึก assets ลงตาราง assets ใน PostgreSQL
                try:
                    var assets_list = model.assets
                    for asset in assets_list:
                        var asset_query = String(
                            "INSERT INTO assets (memory_id, type, filename, path, mime_type, caption, sort_order) "
                            "VALUES (%s, %s, %s, %s, %s, %s, %s)"
                        )
                        var asset_args = Python.list()
                        asset_args.append(memory_id)
                        asset_args.append(asset["type"])
                        asset_args.append(asset["filename"])
                        asset_args.append(asset.get("path", ""))
                        asset_args.append(asset.get("mime_type", ""))
                        asset_args.append(asset.get("caption", ""))
                        asset_args.append(asset.get("order", 0))

                        cursor.execute(asset_query, asset_args)
                except e_asset:
                    print("⚠️ [Javid Core] No assets to save or error parsing assets:", e_asset)

                conn.commit()
                cursor.close()
                conn.close()

                print("💾 [Javid Core] Memory & Assets successfully committed to PostgreSQL!")

            except e:
                print("🔴 [Javid Core] Failed to save memory record to PostgreSQL:", e)