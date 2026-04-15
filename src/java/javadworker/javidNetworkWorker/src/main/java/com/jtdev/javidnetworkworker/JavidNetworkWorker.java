/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 */
package com.jtdev.javidnetworkworker;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.zeromq.ZContext;
import org.zeromq.ZMQ;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public class JavidNetworkWorker {

    // ObjectMapper: ตัวเทพสำหรับจัดการ JSON มหาศาล
    private static final ObjectMapper jsonMapper = new ObjectMapper();

    public static void main(String[] args) {
        try (ZContext context = new ZContext()) {
            ZMQ.Socket socket = context.createSocket(ZMQ.REP);
            socket.bind("tcp://*:5556");

            System.out.println("🚀 [อ.เจมส์] Java Worker เริ่มทำงานแล้ว!");
            System.out.println("📡 สแตนด์บายรอรับ JSON จาก Python ที่พอร์ต 5556...");

            while (!Thread.currentThread().isInterrupted()) {
                // 1. รับข้อความจาก Python
                String promptFromPython = socket.recvStr(0);
                System.out.println("📥 รับงานใหม่: " + promptFromPython);

                // 2. สร้าง JSON Payload แบบเนียนๆ ด้วย Jackson
                ObjectNode ollamaJson = jsonMapper.createObjectNode();
                ollamaJson.put("model", "phi3:mini");
                ollamaJson.put("prompt", promptFromPython);
                ollamaJson.put("stream", false);

                String jsonString = jsonMapper.writeValueAsString(ollamaJson);

                // 3. ส่งหา Ollama ด้วย HttpClient (Native Java 11+)
                String aiResponse = callOllama(jsonString);

                // 4. ส่งคำตอบกลับไปให้ Python
                socket.send(aiResponse);
                System.out.println("📤 ส่งคำตอบกลับเรียบร้อย!");
            }
        } catch (Exception e) {
            System.err.println("❌ พังเพราะ: " + e.getMessage());
        }
    }

    private static String callOllama(String jsonBody) {
        try {
            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(Duration.ofSeconds(20))
                    .build();

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create("http://127.0.0.1:11434/api/generate"))
                    .timeout(Duration.ofMinutes(5)) // ให้เวลา AI คิดได้เต็มที่
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            return response.body();
        } catch (Exception e) {
            return "{\"error\": \"Java Connector: " + e.getMessage() + "\"}";
        }
    }
}
