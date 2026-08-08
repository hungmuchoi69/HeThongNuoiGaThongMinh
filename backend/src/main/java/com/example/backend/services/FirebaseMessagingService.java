package com.example.backend.services;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;



@Service
public class FirebaseMessagingService {

    public void SendNotificationToTopic(String title, String content, String topic, String type, String alertType, Map<String, String> extraData) {
        try {
            // 1. Gom toàn bộ thông tin vào Data Payload
            Map<String, String> dataPayload = new HashMap<>();
            dataPayload.put("click_action", "FLUTTER_NOTIFICATION_CLICK");
            dataPayload.put("title", title);
            dataPayload.put("content", content);
            dataPayload.put("type", type);
            
            // Chỉ đưa alertType vào data nếu có giá trị
            if (alertType != null && !alertType.trim().isEmpty()) {
                dataPayload.put("alert_type", alertType);
            }

            if (extraData != null && !extraData.isEmpty()) {
                dataPayload.putAll(extraData);
            }

            // 2. Cấu hình độ ưu tiên HIGH để tin nhắn đến ngay lập tức
            AndroidConfig androidConfig = AndroidConfig.builder()
                    .setPriority(AndroidConfig.Priority.HIGH)
                    .build();

            // 3. Đóng gói Data-Only Message (KHÔNG dùng .setNotification())
            Message.Builder messageBuilder = Message.builder()
                    .setTopic(topic)
                    .setAndroidConfig(androidConfig)
                    .putAllData(dataPayload);
            
            if(alertType==null || alertType.trim().isEmpty()){
                Notification notification = Notification.builder().setTitle(title).setBody(content).build();
                messageBuilder.setNotification(notification);
            }

            Message mess = messageBuilder.build();
            String response = FirebaseMessaging.getInstance().send(mess);
            System.out.println("🚀 [FCM] Đã gửi Data Message thành công (Topic: " + topic + " | Type: " + type + " | AlertType: " + alertType + "): " + response);

        } catch (Exception e) {
            System.err.println("❌ [FCM] Lỗi gửi thông báo: " + e.getMessage());
        }
    }
}
