package com.example.backend.config;

import java.io.InputStream;

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
            InputStream serviceAccount = new ClassPathResource("firebase-service-account.json").getInputStream();

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();
            
            if(FirebaseApp.getApps().isEmpty()){
                FirebaseApp.initializeApp(options);
                System.out.println(" [Firebase] Khoi tao dich vu firebase thanh cong!");
            }
        } catch (Exception e) {
            System.err.println(" [Firebase] loi khoi tao Firebase: " + e.getMessage());
        }
    }
    
}
