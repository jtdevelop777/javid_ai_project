from std.python import Python, PythonObject
import std.os  # เพิ่ม import เพื่อเช็ค Path ถ้าจำเป็น


struct JavidLogger:
    var logging: PythonObject

    def __init__(out self: Self) raises:
        # 1. ดึงวันที่มาสร้างชื่อไฟล์
        var datetime = Python.import_module("datetime").datetime
        var date_str = datetime.now().strftime("%Y-%m-%d")
        # ใช้ String() ครอบ date_str เพื่อบังคับให้เป็น Mojo String ก่อนนำมาบวก
        var log_filename = (
            String("/mnt/javid_data/projects/javid_ai/javid_core_")
            + String(date_str)
            + String(".log")
        )

        self.logging = PythonObject()
        try:
            var logging_mod = Python.import_module("logging")
            self.logging = logging_mod

            # 2. ใช้ log_filename ที่เราสร้างใหม่
            var _ = logging_mod.basicConfig(
                level=logging_mod.DEBUG,
                format=String("%(asctime)s [%(levelname)s] %(message)s"),
                handlers=[
                    logging_mod.FileHandler(
                        log_filename,  # ใส่ชื่อไฟล์ที่ผูกกับวันที่
                        encoding="utf-8",
                    ),
                    logging_mod.StreamHandler(),
                ],
            )
            # 💡 เติมบรรทัดนี้เพื่อสั่งปิดตาย Log ทุกระดับ 100% ครับกัปตัน!
            # var _ = logging_mod.disable(logging_mod.CRITICAL)
        except:
            print("🔴 [JavidLogger] Failed to initialize Python logging module")

    def debug(self, msg: String):
        try:
            var _ = self.logging.debug(msg)
        except:
            pass

    def info(self, msg: String):
        try:
            var _ = self.logging.info(msg)
        except:
            pass

    def warn(self, msg: String):
        try:
            var _ = self.logging.warning(msg)
        except:
            pass

    def error(self, msg: String):
        try:
            var _ = self.logging.error(msg)
        except:
            pass
