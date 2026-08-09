package com.example.backend.config;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;

import jakarta.annotation.PostConstruct;

@Configuration
public class FirebaseConfig {
    @PostConstruct
    public void initialize(){
        try {
            String firebaseConfig = System.getenv("FIREBASE_CONFIG_JSON");

            InputStream serviceAccount;

            if (firebaseConfig != null && !firebaseConfig.isEmpty()) {
                System.out.println("🚀 [Firebase] Đang khởi tạo bằng biến môi trường trên Render...");
                serviceAccount = new ByteArrayInputStream(firebaseConfig.getBytes(StandardCharsets.UTF_8));
            } else {
                System.out.println("💻 [Firebase] Không tìm thấy biến môi trường, đang đọc file cục bộ...");
                serviceAccount = new ClassPathResource("firebase-service-account.json").getInputStream();
            }

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();
            
            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("✅ [Firebase] Khởi tạo dịch vụ Firebase thành công!");
            }
        } catch (Exception e) {
            System.err.println("❌ [Firebase] Lỗi khởi tạo Firebase: " + e.getMessage());
        }
    }
    
}
