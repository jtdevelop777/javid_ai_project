from fastapi import WebSocket, WebSocketDisconnect
import logging

logger = logging.getLogger("JavidAudioService")

def init_audio_routes(app):
    @app.websocket("/ws/audio")
    async def ws_audio_endpoint(websocket: WebSocket):
        await websocket.accept()
        logger.info("Flutter Client connected to Audio Stream WebSocket.")
        try:
            while True:
                # รับข้อมูลจาก client (รองรับทั้ง text และ bytes)
                message = await websocket.receive()
                
                if "text" in message:
                    cmd = message["text"]
                    logger.info(f"Received audio command: {cmd}")
                    await websocket.send_text(f"Audio Server acknowledged: {cmd}")
                    
                elif "bytes" in message:
                    audio_chunk = message["bytes"]
                    logger.info("Received audio stream chunk bytes.")
                    
        except WebSocketDisconnect:
            logger.info("Audio WebSocket disconnected by client.")
        except Exception as e:
            logger.error(f"Audio WebSocket error: {e}")