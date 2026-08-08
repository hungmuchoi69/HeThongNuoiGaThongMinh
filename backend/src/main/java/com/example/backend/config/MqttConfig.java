package com.example.backend.config;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import com.example.backend.entities.LuaGa;
import com.example.backend.entities.MqttDataHolder;
import com.example.backend.entities.ThongBao;
import com.example.backend.repositories.LuaGaRepository;
import com.example.backend.services.DeviceHeartbeatManager;
import com.example.backend.services.FirebaseMessagingService;
import com.example.backend.services.ThongBaoService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.annotation.PostConstruct;

@Component
public class MqttConfig {
    @Value("${mqtt.broker.url}")
    private String brokerUrl;
    @Value("${mqtt.client.id}")
    private String clientId;
    @Value("${mqtt.topic}")
    private String topic;

    private MqttClient rxClient;
    private MqttClient txClient;
    private MqttClient esspClient;

    @Autowired
    private MqttDataHolder mqttDataHolder;

    @Autowired
    private FirebaseMessagingService firebaseMessagingService;

    @Autowired
    private ThongBaoService thongBaoService;

    @Autowired
    private LuaGaRepository luaGaRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final Map<String,Boolean> alertStateMap = new ConcurrentHashMap<>();

    @PostConstruct
    public void connectToMqtt() {
        try {
            MemoryPersistence persistenceRx = new MemoryPersistence();
            MemoryPersistence persistenceTx = new MemoryPersistence();
            MemoryPersistence persistenceESP32 = new MemoryPersistence();

            String rxClientId = clientId + "_RX_" + UUID.randomUUID().toString().substring(0, 5);
            String txClientId = clientId + "_TX_" + UUID.randomUUID().toString().substring(0, 5);
            String espClientId = clientId + "_ESP_" +UUID.randomUUID().toString().substring(0,5);

            MqttConnectOptions connectOptions = new MqttConnectOptions();
            connectOptions.setCleanSession(true);
            connectOptions.setKeepAliveInterval(60);
            connectOptions.setAutomaticReconnect(true);

            rxClient = new MqttClient(brokerUrl, rxClientId, persistenceRx);
            System.out.println("======> Đang kết nối luồng NHẬN dữ liệu tới broker: " + brokerUrl);
            rxClient.connect(connectOptions);

            esspClient = new MqttClient(brokerUrl, espClientId, persistenceESP32);
            System.out.println("======> Đang kết nối luồng GỬI mệnh lệnh đến chip");
            esspClient.connect(connectOptions);

            txClient = new MqttClient(brokerUrl, txClientId, persistenceTx);
            System.out.println("======> Đang kết nối luồng GỬI thông báo tới broker: " + brokerUrl);
            txClient.connect(connectOptions);

            System.out.println("🎉 ĐÃ KẾT NỐI THÀNH CÔNG CẢ 2 LUỒNG MQTT!");

            rxClient.subscribe(topic, (receivedTopic, message) -> {
                String payload = new String(message.getPayload());
                System.out.println("[MQTT] nhận dữ liệu mới từ Wokwi [" + receivedTopic + "]: " + payload);

                try {
                    if (receivedTopic != null && receivedTopic.startsWith("chuong_ga/users/")) {
                        String[] topicPart = receivedTopic.split("/");
                        String user_id = topicPart[2];
                        UUID userUuid = UUID.fromString(user_id);
                        xuLyDuLieuCamBien(payload, userUuid);
                    }
                } catch (Exception e) {
                    System.err.println("Lỗi phân tách receivedTopic: " + e.getMessage());
                }
            });
        } catch (Exception e) {
            System.err.println("[MQTT] Kết nối tới mqtt thất bại: " + e.getMessage());
        }
    }

    private void xuLyDuLieuCamBien(String payload, UUID userID) {
        try {
            JsonNode jsonNode = objectMapper.readTree(payload);

            LuaGa luaGa = luaGaRepository.findByUserId(userID.toString(), "RAISING");
            if (luaGa == null) {
                System.err.println("⚠️ Không tìm thấy lứa gà trạng thái 'RAISING' cho user: " + userID);
                return;
            }

            float temp = jsonNode.get("temp").floatValue();
            float humidity = jsonNode.get("humidity").floatValue();
            int tds = jsonNode.get("tds").asInt();
            int gas = jsonNode.get("gas").asInt();

            DeviceHeartbeatManager.updateHeartbeat(luaGa.getId());

            mqttDataHolder.updateData(userID, (int) temp, (int) humidity, tds, gas);

            String userNotificationTopic = userID.toString().replaceAll("-", "");
            boolean coSuCoMoi = false;
            int luaGaID=luaGa.getId();

            String keyHardware = luaGaID+"_hong_thiet_bi";
            boolean isHardwareErrorActive = alertStateMap.getOrDefault(keyHardware, false);

            //kiểm tra trạng thái hoạt động của phần cứng

            if(temp==0 || humidity==0){
                try {
                    ThongBao thongBao = new ThongBao();
                    thongBao.setTieu_de("Thông báo khẩn!");
                    thongBao.setNoi_dung("Có lỗi ở phần cứng. Cần kiểm tra ngay lập tức!! Nếu chậm trễ sẽ ảnh hưởng rất lớn đến đàn gà.");
                    thongBao.setDa_doc(false);
                    thongBao.setLoai_tb("event");
                    thongBao.setThoi_gian_tao(LocalDateTime.now());
                    thongBao.setLuaGa(luaGa);

                    firebaseMessagingService.SendNotificationToTopic(thongBao.getTieu_de(), thongBao.getNoi_dung(), 
                    userNotificationTopic, "WARNNING","hong_thiet_bi", null);
                    if(!isHardwareErrorActive){
                        thongBaoService.createThongBao(thongBao);
                        alertStateMap.put(keyHardware, true);
                        System.out.println("🚨 [DB STORED] Lưu sự cố phần cứng lần đầu cho lứa gà: " + luaGaID);
                    }
                    coSuCoMoi=true;
                } catch (Exception e) {
                    System.err.println("Lỗi xử lý thông báo phần cứng: " + e.getMessage());
                }
            }else{
                if(isHardwareErrorActive){
                    alertStateMap.put(keyHardware, false);
                    System.out.println("Phan cung da hoat dong binh thuong cho lua ga "+luaGaID);
                }
            }

            String keyTds = luaGaID + "_nuoc_ban";
            boolean isTdsErrorActive = alertStateMap.getOrDefault(keyTds, false);

            if (tds > 500) {
                try {
                    ThongBao thongBao = new ThongBao();
                    thongBao.setTieu_de("Thông báo khẩn!");
                    thongBao.setNoi_dung(
                            "Nguồn nước dự trữ cho chăn nuôi đang có dấu hiệu bị bẩn, không thích hợp cho đàn gà, hãy xử lý ngay!!");
                    thongBao.setDa_doc(false);
                    thongBao.setLoai_tb("event");
                    thongBao.setThoi_gian_tao(LocalDateTime.now());
                    thongBao.setLuaGa(luaGa);

                    firebaseMessagingService.SendNotificationToTopic(thongBao.getTieu_de(), thongBao.getNoi_dung(),
                            userNotificationTopic,"WARNNING","nuoc_ban", null);
                    if(!isTdsErrorActive){
                        thongBaoService.createThongBao(thongBao);
                        alertStateMap.put(keyTds, true);
                        System.out.println("🚨 [DB STORED] Lưu sự cố nước bẩn lần đầu cho lứa gà: " + luaGaID);
                    }
                    coSuCoMoi = true;
                } catch (Exception e) {
                    System.err.println("Lỗi xử lý thông báo TDS: " + e.getMessage());
                }
            }else if(tds<451){
                if(isTdsErrorActive){
                    alertStateMap.put(keyTds, false);
                    System.out.println("Nguon nuoc da sach tro lai cho lua ga: "+luaGaID);
                }
            }

            if (coSuCoMoi) {
                PublishUnreadCound(userID, luaGa.getId());
            }

            System.out.println(" -> [MQTT] Chuan hoa du lieu thanh cong -> Temp: " + temp + "°C, Humidity: " + humidity
                    + "% " + tds + "ppm");

        } catch (Exception e) {
            System.err.println(" Lỗi phân tách gói tin JSON từ Wokwi toàn cục: " + e.getMessage());
        }
    }

    public void PublishUnreadCound(UUID userId, int luaGaId) {
        try {
            if (txClient != null && txClient.isConnected()) {
                int unreadCount = thongBaoService.getThongBaoChuaDoc(luaGaId);
                String desTopic = "chuong_ga/users/" + userId.toString() + "/notifications";
                String payload = String.format("{\"unreadCount\": %d}", unreadCount);

                MqttMessage mqttMessage = new MqttMessage(payload.getBytes());
                mqttMessage.setQos(0);
                mqttMessage.setRetained(false);

                txClient.publish(desTopic, mqttMessage);
                System.out.println("[MQTT Server] Luồng gửi đã đẩy số lượng thông báo Real-time (" + unreadCount
                        + ") tới topic: " + desTopic);
            } else {
                System.err.println("❌ Luồng gửi (txClient) đang bị mất kết nối, thử kết nối lại...");
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi publish dữ liệu thông báo Real-time: " + e.getMessage());
        }
    }

    public void publishLenhPhanCung(String topic, String mess){
        try {
            if(esspClient!=null && esspClient.isConnected()){
                MqttMessage mqttMessage=new MqttMessage(mess.getBytes());
                mqttMessage.setQos(0);
                mqttMessage.setRetained(false);

                esspClient.publish(topic, mqttMessage);
                System.out.println("[MQTT Server] Luồng gửi đã đẩy mệnh lệnh đến phần cứng mang topic: " + topic);
            }
        } catch (Exception e) {
             System.err.println("Lỗi khi publish dữ liệu mệnh lệnh: " + e.getMessage());
        }
    }
}