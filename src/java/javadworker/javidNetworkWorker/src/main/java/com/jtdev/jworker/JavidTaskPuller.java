/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.jtdev.jworker;

// Java: JavidTaskPuller.java

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.zeromq.ZContext;
import org.zeromq.ZMQ;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public class JavidTaskPuller {

    private static final ObjectMapper jsonMapper = new ObjectMapper();
    private static final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(20))
            .build();

    public static void main(String[] args) {
        try (ZContext context = new ZContext()) {
            // สร้างท่อรับงานแบบ PULL
            ZMQ.Socket socket = context.createSocket(ZMQ.PULL);
            socket.bind("tcp://*:5556");

            System.out.println("🚀 [อ.เจมส์] Java Worker เริ่มทำงานแล้ว!");
            System.out.println("📡 สแตนด์บายรอ 'ดึงงาน' จาก Python ที่พอร์ต 5556...");

            while (!Thread.currentThread().isInterrupted()) {
                // 1. ดึงงานออกมาจาก Buffer (ถ้าไม่มีงานมันจะรอตรงนี้)
                String prompt = socket.recvStr(0);
                if (prompt != null) {
                    System.out.println("📥 ได้รับงานใหม่: " + prompt);

                    // 2. ประมวลผลคุยกับ Ollama
                    String aiResponse = callOllama(prompt);
                    
                    // 3. บันทึกผลลัพธ์ (กัปตันใส่ Logic บันทึก DB ในนี้ได้เลย)
                    saveToDatabase(aiResponse);
                }
            }
        } catch (Exception e) {
            System.err.println("❌ Java Error: " + e.getMessage());
        }
    }

    private static String callOllama(String prompt) {
        try {
            // สร้าง JSON Payload ที่ถูกต้อง (แก้ model เป็น phi3:mini หรือ llama3 ตามที่กัปตันมี)
            ObjectNode ollamaJson = jsonMapper.createObjectNode();
            ollamaJson.put("model", "phi3:mini"); 
            ollamaJson.put("prompt", prompt);
            ollamaJson.put("stream", false);
            
            String jsonString = jsonMapper.writeValueAsString(ollamaJson);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create("http://127.0.0.1:11434/api/generate"))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(jsonString))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            return response.body();
        } catch (Exception e) {
            return "{\"error\": \"" + e.getMessage() + "\"}";
        }
    }

    private static void saveToDatabase(String aiResponse) {
        // เบื้องต้นให้ Print ออกมาดูก่อนว่า Ollama ตอบอะไรมา
        System.out.println("✅ AI ตอบกลับมาว่า: " + aiResponse);
        System.out.println("💾 [อ.เจมส์] เตรียมบันทึกความรู้ลงคลัง...");
    }
}