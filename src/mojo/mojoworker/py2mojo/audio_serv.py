from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import logging
import json
import os
import uuid
import sqlite3
from faster_whisper import WhisperModel

logger = logging.getLogger("JavidAudioService")

# โหลดโมเดล Whisper ไว้รอรับงาน (โหลดรอบเดียวจบ)
model_size = "base"
print(f"Loading Whisper model ({model_size})...")
whisper_model = WhisperModel(model_size, device="cpu", compute_type="int8")
print("Whisper model loaded successfully!")

def save_transcript_to_db(text: str):
    conn = sqlite3.connect("javid_ai.db")
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS transcripts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cursor.execute("INSERT INTO transcripts (content) VALUES (?)", (text,))
    conn.commit()
    conn.close()

app = FastAPI()

@app.websocket("/ws/audio")
async def audio_websocket(websocket: WebSocket):
    await websocket.accept()
    print("Flutter Client connected to Audio Stream WebSocket.")
    
    try:
        while True:
            audio_bytes = await websocket.receive_bytes()
            print(f"Received audio bytes chunk. Size: {len(audio_bytes)}")
            
            unique_filename = f"temp_audio_{uuid.uuid4().hex}.wav"
            temp_file_path = os.path.join("/tmp", unique_filename)
            
            with open(temp_file_path, "wb") as f:
                f.write(audio_bytes)
                
            try:
                segments, info = whisper_model.transcribe(
                    temp_file_path, 
                    beam_size=5, 
                    language="th",
                    no_speech_threshold=0.6,
                    condition_on_previous_text=False
                )

                transcript_text = " ".join([segment.text for segment in segments]).strip()

                # เช็คว่ามีข้อความจริง ๆ และไม่ใช่เสียงดนตรี/นอยส์
                if transcript_text:
                    logger.info(f"Transcribed Text: {transcript_text}")
                    save_transcript_to_db(transcript_text)
                    response_payload = {"status": "success", "transcript": transcript_text}
                else:
                    logger.info("Skipping: Detected background music or no clear speech.")
                    response_payload = {"status": "ignored", "message": "เสียงดนตรีหรือไม่มีเสียงพูดครับกัปตัน"}
                print(f"Transcribed Text: {transcript_text}")
                
                if transcript_text:
                    save_transcript_to_db(transcript_text)
                    
                await websocket.send_text(f"[STT Success]: {transcript_text}")
                
            except Exception as e:
                print(f"Error during transcription: {e}")
                await websocket.send_text(f"[STT Error]: {str(e)}")
                
            finally:
                if os.path.exists(temp_file_path):
                    os.remove(temp_file_path)
                    
    except WebSocketDisconnect:
        print("Flutter Client disconnected from Audio Stream WebSocket.")


# เพิ่มฟังก์ชัน init_audio_routes กลับเข้ามาเพื่อให้ระบบหลักเรียกใช้งานได้ตามปกติครับกัปตัน
def init_audio_routes(app: FastAPI):
    @app.websocket("/ws/audio")
    async def audio_websocket(websocket: WebSocket):
        await websocket.accept()
        logger.info("Flutter Client connected to Audio Stream WebSocket.")
        
        try:
            while True:
                audio_bytes = await websocket.receive_bytes()
                logger.info(f"Received audio bytes chunk. Size: {len(audio_bytes)}")
                
                unique_filename = f"temp_audio_{uuid.uuid4().hex}.wav"
                temp_file_path = os.path.join("/tmp", unique_filename)
                
                with open(temp_file_path, "wb") as f:
                    f.write(audio_bytes)
                    
                try:
                    segments, info = whisper_model.transcribe(temp_file_path, beam_size=5)
                    transcript_text = " ".join([segment.text for segment in segments]).strip()
                    logger.info(f"Transcribed Text: {transcript_text}")
                    
                    if transcript_text:
                        save_transcript_to_db(transcript_text)
                        
                    response_payload = {
                        "status": "success",
                        "transcript": transcript_text
                    }
                    await websocket.send_text(json.dumps(response_payload, ensure_ascii=False))
                    
                except Exception as e:
                    logger.error(f"Error during transcription: {e}")
                    error_payload = {
                        "status": "error",
                        "message": str(e)
                    }
                    await websocket.send_text(json.dumps(error_payload, ensure_ascii=False))
                    
                finally:
                    if os.path.exists(temp_file_path):
                        os.remove(temp_file_path)
                        
        except WebSocketDisconnect:
            logger.info("Audio WebSocket disconnected by client.")
        except Exception as e:
            logger.error(f"Audio WebSocket error: {e}")        