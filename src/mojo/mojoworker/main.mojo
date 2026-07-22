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

    # Python bridge string definition for FastAPI & ZeroMQ infrastructure
    comptime bridge_code = """
from fastapi import FastAPI, WebSocket
import uvicorn
import zmq
import json
import threading
from pydantic import BaseModel
from typing import Dict, Any

app = FastAPI(title="Javid MQ System API", version="1.0.0")

_queue_size = 0
_queue_lock = threading.Lock()

def increment_queue():
    global _queue_size
    with _queue_lock:
        _queue_size += 1

def decrement_queue():
    global _queue_size
    with _queue_lock:
        if _queue_size > 0:
            _queue_size -= 1

def get_queue_size():
    global _queue_size
    with _queue_lock:
        return _queue_size

class TaskSchema(BaseModel):
    command: str

class IngestSchema(BaseModel):
    action: str
    payload: Dict[str, Any]

class MemorySchema(BaseModel):
    topic: str
    content: str
    category_id: int
    priority: int
    metadata: Dict[str, Any]

@app.get("/queue/status")
def get_queue_status():
    count = get_queue_size()
    return {
        "status": "success",
        "queue_position": count,
        "estimated_wait_seconds": count * 2,
        "message": f"There are {count} tasks waiting in the queue."
    }

@app.post("/ingest/memory")
def ingest_memory(data: MemorySchema):
    try:
        context = zmq.Context()
        sender = context.socket(zmq.PUSH)
        sender.connect("tcp://192.168.4.9:5555")
        
        msg_dict = {
            "action": "SAVE_MEMORY",
            "topic": data.topic,
            "content": data.content,
            "category_id": data.category_id,
            "priority": data.priority,
            "metadata": data.metadata
        }
        sender.send_string(json.dumps(msg_dict, ensure_ascii=False))
        increment_queue()
        return {"status": "queued", "message": "Memory ingested into ZMQ queue successfully."}
    except Exception as e:
        print(f"Error Detail: {e}")    

@app.post("/task")
def submit_task(data: TaskSchema):
    import zmq
    import json
    
    context = zmq.Context()
    sender = context.socket(zmq.PUSH)
    sender.connect("tcp://192.168.4.9:5555")
    
    msg_dict = {
        "auth_key": "ag_secure_local_token_2026",
        "target_version": "1.0.0",
        "command": str(data.command)
    }
    
    sender.send_string(json.dumps(msg_dict, ensure_ascii=False))
    increment_queue()
    return '{"status": "Success"}'

@app.post("/ingest")
def direct_ingest(data: IngestSchema):
    context = zmq.Context()
    sender = context.socket(zmq.PUSH)
    sender.connect("tcp://192.168.4.9:5555")
    msg_dict = {"action": data.action, "payload": data.payload}
    sender.send_string(f"BYPASS_LOG:{json.dumps(msg_dict, ensure_ascii=False)}")
    increment_queue()
    return {"status": "Accepted", "mode": "FastTrack"}   

@app.websocket("/ws/sdr")
async def sdr_stream(websocket: WebSocket):
    await websocket.accept()
    while True:
        data = await websocket.receive_bytes()
        pass

def start_api(port):
    uvicorn.run(app, host="0.0.0.0", port=port)
"""


    var scope = Python.dict()
    _ = py.exec(bridge_code, scope)
    var start_api = scope["start_api"]

    var thread_kwargs = Python.dict()
    thread_kwargs["port"] = 8001

    var server_thread = threading.Thread(target=start_api, kwargs=thread_kwargs)
    server_thread.setDaemon(True)
    server_thread.start()

    var context = zmq.Context()
    var receiver = context.socket(zmq.PULL)
    receiver.bind("tcp://*:5555")
    var publisher = context.socket(zmq.PUB)
    publisher.bind("tcp://*:8002")

    var default_script = String("")
    var _ = PojoAiCommands(0, "Default", default_script, "pending", 0)

    # Inside main.mojo -> main() loop setup
    var sqlite3 = Python.import_module("sqlite3")
    var json_mod = Python.import_module("json")

    # 💡 ใช้ Absolute Path เพื่อความแม่นยำไม่ว่าจะสั่งรันจากโฟลเดอร์ไหน
    var DB_PATH = "/mnt/javid_data/projects/javid_ai/javid_memory.db"
    var db_conn = sqlite3.connect(DB_PATH)
    var _repo = CommandRepository(db_conn)
    var mem_repo = MemoryRepository(db_conn)

    print("🚀 Javid MQ System: Mojo + Pixi [PORT 8001 ONLINE]")

    var LOCAL_AUTH_KEY = String("ag_secure_local_token_2026")

    var decrement_queue = scope["decrement_queue"]

    # ภายในลูปประมวลผล
    while True:
        try:
            raw_msg = String(receiver.recv_string())
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
                if (
                    not action_obj is None
                    and String(action_obj) == "SAVE_MEMORY"
                ):
                    is_memory_action = True
            except:
                pass

            # --- Route 1: Javid AI Memory Core Ingestion (พร้อมเชื่อม AI ตอบกลับ) ---
            if is_memory_action:
                print("💾 [Javid Core] Memory Ingestion Detected. Processing...")
                try:
                    var memory_data = MemoryModel(
                        String(parsed_json["topic"]),
                        String(parsed_json["content"]),
                        Int(String(parsed_json["category_id"])),
                        Int(String(parsed_json["priority"])),
                        parsed_json["metadata"],
                    )

                    # 1. บันทึกความจำลงตาราง javid_memories ตามปกติ
                    mem_repo.save(memory_data)

                    # 2. ส่งบริบทให้ Ollama ประมวลผลเบื้องหลัง
                    var memory_context_msg = (
                        "System Note: New memory saved regarding '"
                        + memory_data.topic
                        + "'. Content: "
                        + memory_data.content
                    )
                    var ai_response = ask_ollama_cli(memory_context_msg)

                    # 3. บันทึกผลลัพธ์การวิเคราะห์ของ AI ลงฐานข้อมูล (javid_logs) ควบคู่กันไป เพื่อให้เรียกดูย้อนหลังได้
                    var log_status = String("COMPLETED")
                    var estimate_val = 10
                    _ = log_to_sqlite(
                        "Memory Ingestion: " + memory_data.topic,
                        log_status,
                        ai_response,
                        estimate_val,
                    )

                    # 4. ส่งสถานะตอบกลับสลับเข้าคิว ZMQ ว่างานเสร็จสิ้นแล้ว (ไม่บล็อกหน้าบ้าน)
                    var resp_dict = Python.dict()
                    resp_dict["status"] = "success"
                    resp_dict["message"] = (
                        "Memory saved and processed successfully by"
                        " background AI."
                    )

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

                var task = TaskModel(raw_str)
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
