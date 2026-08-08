package com.example.backend.services;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.example.backend.entities.CamBienHomNay;
import com.example.backend.entities.LichSuPhatTrien;
import com.example.backend.entities.LuaGa;
import com.example.backend.entities.MqttDataHolder;
import com.example.backend.entities.ThongBao;
import com.example.backend.repositories.CamBienAverage;
import com.example.backend.repositories.CamBienHomNayRepository;
import com.example.backend.repositories.LichSuPhatTrienRepository;
import com.example.backend.repositories.LuaGaRepository;
import com.example.backend.repositories.ThongBaoRepository;

@Component
public class AutoSaveSensorLog {
    @Autowired
    private MqttDataHolder mqttDataHolder;

    @Autowired
    private CamBienHomNayService camBienHomNayService;

    @Autowired
    private CamBienHomNayRepository camBienHomNayRepository;

    @Autowired
    private LichSuPhatTrienRepository lichSuPhatTrienRepository;

    @Autowired
    private FirebaseMessagingService firebaseMessagingService;

    @Autowired
    private LuaGaRepository luaGaRepository;

    @Autowired
    private ThongBaoRepository thongBaoRepository;

    private Map<String,Boolean> stateHardwareMap = new ConcurrentHashMap<>();

    @Scheduled(cron = "0 0/15 * * * ?")
    public void executeSaveTask() {
        try {
            mqttDataHolder.getAllStorage().forEach((userId, data) -> {
                LuaGa lluaGa = luaGaRepository.findByUserId(userId.toString(), "RAISING");
                if (lluaGa != null) {

                    CamBienHomNay cb = new CamBienHomNay();
                    cb.setLuaGa(lluaGa);
                    cb.setNhiet_do(data.getNhiet_do());
                    cb.setDo_am(data.getDo_am());
                    cb.setTds(data.getTds());
                    cb.setGas(data.getGas());
                    cb.setLogged_at(LocalDateTime.now());

                    camBienHomNayService.createCamBienHomNay(cb);
                    System.out.println(" Đã đóng gói và lưu dữ liệu CamBienHomNay thành công!");
                }
            });

        } catch (Exception e) {
            System.err.println("Lỗi luồng lưu tự động" + e.getMessage());
        }
    }

    @Scheduled(cron = "0 55 23 * * ?")
    public void executeDailySumaryTask() {
        try {
            LocalDate homnay = LocalDate.now();
            LocalDateTime start = homnay.atStartOfDay();
            LocalDateTime end = homnay.atTime(23, 54, 59);

            List<LuaGa> lgList = luaGaRepository.findByTrangThai("RAISING");
            for (LuaGa luaGa : lgList) {
                CamBienAverage avgData = camBienHomNayRepository.getDailyAverage(start, end, luaGa.getId());
                if (avgData != null) {
                    Optional<LichSuPhatTrien> existingRecord = lichSuPhatTrienRepository.getLSByIdVaNgay(luaGa.getId(),
                            homnay);
                    LichSuPhatTrien lSuPhatTrien;

                    if (existingRecord.isPresent()) {
                        lSuPhatTrien = existingRecord.get();
                        lSuPhatTrien.setNhiet_do_tb(avgData.getAvgTemp());
                        lSuPhatTrien.setDo_am_tb(avgData.getAvgHumi());
                        lSuPhatTrien.setTds_tb(avgData.getAvgTds());
                        lSuPhatTrien.setGas_tb(avgData.getAvgGas());

                        lichSuPhatTrienRepository.save(lSuPhatTrien);

                    } else {
                        lSuPhatTrien = new LichSuPhatTrien();
                        float tiLeSong =luaGa.getSo_luong_hien_tai()/luaGa.getSo_luong_hien_tai();

                        lSuPhatTrien.setNhiet_do_tb(avgData.getAvgTemp());
                        lSuPhatTrien.setDo_am_tb(avgData.getAvgHumi());
                        lSuPhatTrien.setTds_tb(avgData.getAvgTds());
                        lSuPhatTrien.setGas_tb(avgData.getAvgGas());
                        lSuPhatTrien.setNgay(homnay);
                        lSuPhatTrien.setLuaGa(luaGa);
                        lSuPhatTrien.setTi_le_song(tiLeSong);
                        lichSuPhatTrienRepository.save(lSuPhatTrien);
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Loi tong hop du lieu: " + e.getMessage());
        }
    }

    @Scheduled(fixedRate = 60000)
    public void scanDevicesForTimeout() {
        LocalDateTime now = LocalDateTime.now();
        for (Integer luaGaId : DeviceHeartbeatManager.getAllTrackedDevices()) {
            LocalDateTime lastUpd = DeviceHeartbeatManager.getLastActiveTime(luaGaId);
            String keyMKN = luaGaId + "_mat_ket_noi";
            boolean isMKNErrorActive = stateHardwareMap.getOrDefault(keyMKN, false);
            if (lastUpd != null) {
                if (now.isAfter(lastUpd.plusMinutes(1))) {
                    LuaGa lg = luaGaRepository.findByIdLG(luaGaId);
                    ThongBao thongBao = new ThongBao();
                    thongBao.setTieu_de("Thông báo khẩn!!");
                    thongBao.setNoi_dung(
                            "Phần cứng đã mất kết nối mạng hoặc bị hỏng bộ não xử lý. Cần kiểm tra ngay, nếu chậm trễ sẽ ảnh hưởng đến đàn gà!");
                    thongBao.setDa_doc(false);
                    thongBao.setThoi_gian_tao(LocalDateTime.now());
                    thongBao.setLoai_tb("event");
                    thongBao.setLuaGa(lg);

                    firebaseMessagingService.SendNotificationToTopic(
                            thongBao.getTieu_de(),
                            thongBao.getNoi_dung(),
                            lg.getUserId().replaceAll("-", ""),
                            "WARNNING",
                            "mat_ket_noi",
                            null);
                    if(!isMKNErrorActive){
                        thongBaoRepository.save(thongBao);
                        stateHardwareMap.put(keyMKN, true);
                    } 
                }else{
                    if(isMKNErrorActive)
                        stateHardwareMap.put(keyMKN, false);
                }
            }
        }
    }
}
