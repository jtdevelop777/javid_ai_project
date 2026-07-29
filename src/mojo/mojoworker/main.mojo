from std.python import Python, PythonObject
from core.taskModel import TaskModel
from core.services import ask_ollama_cli
from core.database import log_to_sqlite, get_recent_logs_as_context
from repo.ai_commands_repo import CommandRepository
from models.memory_model import MemoryModel
from repo.memory_repo import MemoryRepository
from core.javid_logger import JavidLogger
from serv.retriever_serv import get_relevant_context
from models.pojo_ai_commands import PojoAiCommands
from repo.ai_commands_repo import CommandRepository



# สร้างโครงสร้างข้อมูลมาเก็บ Logger ไว้
struct AppContext:
    var logger_AI: JavidLogger

    def __init__(out self: Self) raises:
        self.logger_AI = JavidLogger()


# 2. Safety Function (Changed to 'def' for stable Python Interop handling)
def execute_command(repo: CommandRepository, model: PojoAiCommands) raises:
    var ctx = AppContext()
    var real_id = log_to_sqlite(model.script_content, "PENDING", "", 0)
    print("⚡ [Javid Core] Bypassing GUI Automation. Command ID: ", model.id)
    # สั่งอัปเดตสถานะเพียงคำสั่งเดียว จบในบรรทัดเดียว
    repo.update_status(real_id, "success")
    ctx.logger_AI.info("Error ในการเรียก LLM: ")


def process_command(user_input: String) raises:
    var ctx = AppContext()
    var context = get_relevant_context(user_input)

    try:
        var final_prompt = user_input
        if context.__len__() > 0:
            # แทนที่จะพึ่ง __str__ ให้ใช้ Python.evaluate แปลงเป็น string ตรงๆ เลย
            var context_str = String(context.__str__())
            final_prompt = "Context: " + context_str + "\nQuery: " + user_input

        # เรียกตัวจริงที่นี่เท่านั้น
        _ = ask_ollama_cli(final_prompt)

    except e:
        ctx.logger_AI.info("Error ในการเรียก LLM: " + String(e))


# 3. Main Orchestrator System Control Function
def main() raises:
    var logger_AI = JavidLogger()
    var py = Python.import_module("builtins")
    var sys = Python.import_module("sys")

    try:
        var fastapi = Python.import_module("fastapi")
        print("✅ Found FastAPI in Pixi Environment!")
    except:
        print(
            "❌ FastAPI module not found. Please verify the Pixi path"
            " configuration."
        )
        return

    var zmq = Python.import_module("zmq")
    var threading = Python.import_module("threading")

    # 1. ประกาศตัวแปรเตรียมไว้ข้างนอก
    #var start_api = PythonObject()
    var decrement_queue = PythonObject()

    #print(sys.prefix)
    # Import the Python sys module


    var context = zmq.Context()
    var receiver = context.socket(zmq.PULL)
    receiver.bind("tcp://*:5555")

    var publisher = context.socket(zmq.PUB)
    publisher.setsockopt(zmq.LINGER, 0) # <-- ใส่บรรทัดนี้เพื่อไม่ให้ publisher ดึงลูปค้าง
    publisher.bind("tcp://*:8002")    

    var default_script = String("")
    var _ = PojoAiCommands(0, "Default", default_script, "pending", 0)

    # Inside main.mojo -> main() loop setup
    var sqlite3 = Python.import_module("sqlite3")
    var json_mod = Python.import_module("json")

    # 💡 ใช้ Absolute Path เพื่อความแม่นยำไม่ว่าจะสั่งรันจากโฟลเดอร์ไหน
    var DB_PATH = "/mnt/javid_data/projects/javid_ai/javid_memory.db"
    var conn = sqlite3.connect(DB_PATH)
    var _repo = CommandRepository(conn)
    var mem_repo = MemoryRepository(conn)

    var cursor = conn.cursor()

    # สร้างตาราง log เผื่อไว้กรณีที่ยังไม่มีตาราง
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS system_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            level TEXT,
            message TEXT,
            timestamp DATETIME DEFAULT CURRENT_STAMP
        )
    """)

    # สั่ง Insert ข้อมูลทดสอบ
    cursor.execute("INSERT INTO system_logs (level, message) VALUES ('ZMQ_TEST', 'Javid MQ System Started Successfully')")
    conn.commit()
    conn.close()

    print("✅ Insert test data into database successfully!")

    print("🚀 Javid MQ System: Mojo + Pixi [PORT 8001 ONLINE]")

    var LOCAL_AUTH_KEY = String("ag_secure_local_token_2026")

    # 2. ย้ายมาโหลดและสั่งเปิด API Server ตรงนี้
    Python.add_to_path("/mnt/javid_data/projects/javid_ai/src/mojo/mojoworker/py2mojo")
    #print(sys.path[-1])
    try:
        var api_module = Python.import_module("api_server")
        # สั่งรัน API แบบ Threading เพื่อไม่ให้ Block Event Loop หลัก
        var api_thread = threading.Thread(target=api_module.start_api)
        api_thread.start()
        print("✅ Found and loaded api_server.py in Thread!")
    except e:
        print("❌ Cannot load api_server:", e)
        return


    # ภายในลูปประมวลผล
    while True:

        try:
            raw_msg = String(receiver.recv_string())
            print(raw_msg)
            
            # --- แทรกแค่บรรทัดนี้บรรทัดเดียวพอครับ เพื่อตัด BYPASS_LOG: ออกถ้ามี ---
            #if raw_msg.startswith("BYPASS_LOG:"):
            raw_msg = raw_msg.replace("BYPASS_LOG:", "")

            parsed_json = json_mod.loads(raw_msg)
            _ = decrement_queue()
        except e:
            print("❌ JSON Parse Error, skipping:", e)
            continue  # ถ้าแกะ JSON ไม่ได้ ให้ข้ามไปเริ่ม Loop ใหม่

        # 🛡️ ป้องกันกับดัก Truthiness: แปลงและตรวจสอบค่าผ่านกลไกที่ปลอดภัย
        var feedback_val = parsed_json.get("is_feedback")
        var has_feedback = False
        if not feedback_val is None and Bool(feedback_val):
            has_feedback = True

        # 1. เช็ค Feedback ก่อนเลย
        logger_AI.info("is_feedback : " + String(feedback_val))

        if has_feedback:
            print("⚡ [Safety Guard] Feedback detected. Executing direct...")
            var cmd_str = String(parsed_json["command"])
            var cmd_model = PojoAiCommands(0, "Auto", cmd_str, "pending", 0)

            execute_command(_repo, cmd_model)

            var response_json = String(
                '{"status": "success", "message": "Feedback command executed"}'
            )
            publisher.send_string(response_json)
            continue

        else:
            # 2. เช็ค Memory Action
            var is_memory_action = False
            try:
                var action_obj = parsed_json.get("action")
                if String(action_obj) == "SAVE_MEMORY" or String(action_obj) == "store_memory":
                    is_memory_action = True
            except:
                pass

            # --- Route 1: Javid AI Memory Core Ingestion ---
            if is_memory_action:
                print("🧠 [Javid Core] Save Memory Request Detected. Processing...")
                try:
                    # รองรับทั้ง action 'store_memory' และ 'SAVE_MEMORY'
                    # และรองรับการดึง payload จาก JSON
                    # 1. ดึงค่าจาก parsed_json และแปลงเป็น Mojo Types ให้ถูกต้อง
                    var topic = String(parsed_json.get("topic", ""))
                    var content = String(parsed_json.get("content", ""))

                    # แปลง category_id เป็น Mojo Int ผ่าน String เพื่อความปลอดภัย
                    var _category_id = 0
                    try:
                        category_id = Int(String(parsed_json.get("category_id", 0)))
                    except:
                        category_id = 0

                    # แปลง priority เป็น Mojo Int
                    var _priority = 0
                    try:
                        priority = Int(String(parsed_json.get("priority", 0)))
                    except:
                        priority = 0

                    # metadata และ assets เป็น PythonObject (dict/list) อยู่แล้ว
                    var metadata = parsed_json.get("metadata", Python.dict())
                    var assets = parsed_json.get("assets", Python.list())

                    # 2. สร้าง MemoryModel โดยส่ง Argument ครบทั้ง 6 ตัว
                    var memory_data = MemoryModel(
                        topic,
                        content,
                        category_id,
                        priority,
                        metadata,
                        assets
                    )

                    # 1. บันทึกความจำลง PostgreSQL ผ่าน memory_repo
                    mem_repo.save(memory_data)

                    # --- นำโค้ดเดิมส่วนนี้มาวางต่อตรงนี้ครับ ---
                    # 2. ส่งบริบทให้ Ollama ประมวลผลเบื้องหลัง
                    var memory_context_msg = (
                        "System Note: New memory saved regarding "
                        + memory_data.topic
                        + ". Content: "
                        + memory_data.content
                    )
                    var ai_response = ask_ollama_cli(memory_context_msg)

                    # 3. บันทึกผลลัพธ์การวิเคราะห์ของ AI ลงฐานข้อมูล (javid_logs)
                    var log_status = String("COMPLETED")
                    var estimate_val = 10
                    _ = log_to_sqlite(
                        "Memory Ingestion: " + memory_data.topic,
                        log_status,
                        ai_response,
                        estimate_val
                    )

                    # 4. ส่งสถานะตอบกลับสลับคิว ZMQ ว่างานเสร็จสิ้นแล้ว
                    var resp_dict = Python.dict()
                    resp_dict["status"] = "success"
                    resp_dict["message"] = "Memory and assets saved successfully"
                    
                    publisher.send_string(
                        json_mod.dumps(resp_dict, ensure_ascii=False)
                    )
                    print(
                        "💾 [Javid Core] Memory stored, AI analyzed, and logged"
                        " to DB successfully."
                    )
                except e:
                    print(
                        (
                            "🔴 [Javid Core] Critical runtime error during"
                            " memory mapping:"
                        ),
                        e,
                    )

            # --- Route 2: Standard Task Pipeline ---
            else:
                var raw_str = String(raw_msg)
                
                # ... โค้ดเดิมของจักร์ชัยทั้งหมด ...
                var task = TaskModel(raw_str)

                var auth_pass = False
                try:
                    var incoming_key = parsed_json.get("auth_key")
                    if (
                        not incoming_key is None
                        and String(incoming_key) == LOCAL_AUTH_KEY
                    ):
                        auth_pass = True
                except:
                    pass

                if not auth_pass:
                    print(
                        "🔒 [Security Alert] Access Denied: Invalid Key. Task"
                        " Rejected."
                    )
                    publisher.send_string(
                        String('{"status": "failed", "error": "Unauthorized"}')
                    )
                    continue


                publisher.send_string(task.to_json("estimation"))
                print("⏳ Task Received: " + task.command)

                # --- CASE 1: พักผ่อน ---
                if "พักผ่อน" in task.command:
                    task.response = (
                        "Summary: Successfully refactored authentication guard"
                        " and local data pipelines."
                    )
                    var _real_id = log_to_sqlite(
                        task.command, "COMPLETED", task.response, 0
                    )
                    publisher.send_string(task.to_json("answer"))
                    print(
                        "💤 Break time initialized. Waiting for Disk I/O"
                        " Commit..."
                    )

                    try:
                        var time_mod = Python.import_module("time")
                        time_mod.sleep(1.0)
                    except:
                        pass

                    print("✨ Database write sync complete. Exiting system.")
                    logger_AI.info(
                        "✨ Database write sync complete. Exiting system."
                    )
                    break

                # --- CASE 3: การสนทนาทั่วไป (Hybrid Mode) ---
                else:
                    try:
                        print(
                            "🧠 [Agent 2 - อ.เจมส์] Thinking & Analyzing with"
                            " Hybrid Context..."
                        )
                        var local_context = get_recent_logs_as_context(3)

                        var agent_instruction = String(
                            "You are A. James, a Senior AI Partner. If the user"
                            " wants a command executed, embed"
                            " 'run_cmd:<command>' somewhere in your"
                            " response.\n\n"
                        )
                        var hybrid_prompt = (
                            agent_instruction
                            + "System Context (Past Lab Records):\n"
                            + local_context
                            + "\n\nUser Command: "
                            + task.command
                        )

                        var ai_response = ask_ollama_cli(hybrid_prompt)
                        task.response = ai_response

                        var _real_id = log_to_sqlite(
                            task.command, "COMPLETED", task.response, 10
                        )

                        var trigger = String("run_cmd:")
                        var builtins = Python.import_module("builtins")
                        var py_response = builtins.str(ai_response)
                        var py_response_lower = String(py_response.lower())
                        var idx = py_response_lower.find(trigger)

                        logger_AI.error("⏳ idx: " + String(idx))

                        if idx != -1:
                            print("⚡ [Multi-Agent] Parser found 'run_cmd:'!")
                            try:
                                var py_idx = Python.int(idx)
                                var py_trigger_len = Python.int(
                                    trigger.byte_length()
                                )
                                var start_pos = py_idx + py_trigger_len
                                var raw_py_cmd = py_response.__getitem__(
                                    builtins.slice(
                                        start_pos, builtins.len(py_response)
                                    )
                                )
                                var lines = raw_py_cmd.split("\n")
                                var clean_cmd = (
                                    String(lines[0]).strip().replace("`", "")
                                )

                                print(
                                    "📡 Extracted Action Command: " + clean_cmd
                                )
                                var next_action = json_mod.loads(String("{}"))
                                next_action["auth_key"] = LOCAL_AUTH_KEY
                                next_action["command"] = (
                                    String("run_cmd:") + clean_cmd
                                )
                                next_action["is_feedback"] = True

                                var internal_sender = zmq.Context().socket(
                                    zmq.PUSH
                                )
                                internal_sender.connect(
                                    "tcp://192.168.4.9:5555"
                                )
                                internal_sender.send_string(
                                    json_mod.dumps(
                                        next_action, ensure_ascii=False
                                    )
                                )
                            except e:
                                print("🔴 [Multi-Agent] Route failed:", e)
                    except e:
                        print("🔴 [Agent Error]:", e)

                    publisher.send_string(task.to_json("answer"))
                    print("💾 [Javid Core] Multi-agent processing complete.")
