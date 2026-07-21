# src/mojo/mojoworker/services/processor_service.mojo
from std.python import PythonObject


def preprocess_data(raw_data: PythonObject) -> PythonObject:
    # Logic ในการคัดกรอง หรือจัดรูปแบบข้อมูลก่อนเข้าฐานข้อมูล
    # กัปตันอาจจะเพิ่มการดึงเฉพาะ key ที่ต้องการที่นี่ครับ
    var cleaned_data = raw_data  # ปรับแต่งได้ตามความเหมาะสม
    return cleaned_data
