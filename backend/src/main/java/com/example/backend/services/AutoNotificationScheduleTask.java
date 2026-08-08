package com.example.backend.services;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.example.backend.config.MqttConfig;
import com.example.backend.entities.DanhMucVaccine;
import com.example.backend.entities.LuaGa;
import com.example.backend.entities.ThongBao;
import com.example.backend.entities.TieuChuanPhatTrien;
import com.example.backend.repositories.CamBienHomNayRepository;
import com.example.backend.repositories.DanhMucVaccineRepository;
import com.example.backend.repositories.LuaGaRepository;
import com.example.backend.repositories.ThongBaoRepository;
import com.example.backend.repositories.TieuChuanPhatTrienRepository;
import com.fasterxml.jackson.databind.ObjectMapper;

@Component
public class AutoNotificationScheduleTask {
    @Autowired
    private FirebaseMessagingService firebaseMessagingService;

    @Autowired
    private ThongBaoRepository thongBaoRepository;

    @Autowired
    private LuaGaRepository luaGaRepository;

    @Autowired
    private TieuChuanPhatTrienRepository tieuChuanPhatTrienRepository;

    @Autowired
    private CamBienHomNayRepository camBienHomNayRepository;

    @Autowired
    private DanhMucVaccineRepository danhMucVaccineRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private MqttConfig mqttConfig;

    @Scheduled(cron = "0 0 7 * * ?")
    // @Scheduled(fixedRate = 60000)
    public void executeDailyScheduleReminder() {
        try {
            List<LuaGa> luaGa = luaGaRepository.findByTrangThai("RAISING");
            LocalDate homnay = LocalDate.now();

            for (LuaGa luaGa2 : luaGa) {
                long ngayTuoi = ChronoUnit.DAYS.between(luaGa2.getNgay_nhap(), homnay) + 1;
                List<DanhMucVaccine> vaccines = danhMucVaccineRepository.findDanhMucVaccinesByNgayTuoi((int) ngayTuoi);

                // =============================================================
                // 1. NHẮC NHỞ KIỂM TRA ĐÁNH GIÁ ĐÀN GÀ (MỖI 7 NGÀY)
                // =============================================================
                if (ngayTuoi % 7 == 0) {
                    ThongBao thongBao = new ThongBao();
                    thongBao.setTieu_de("Thông báo lịch trình chăn nuôi!");
                    thongBao.setNoi_dung(
                            "Hôm nay là ngày tuổi thứ " + ngayTuoi + ", hãy thực hiện kiểm tra đánh giá đàn gà!");
                    thongBao.setDa_doc(false);
                    thongBao.setLoai_tb("growth");
                    thongBao.setThoi_gian_tao(LocalDateTime.now());
                    thongBao.setLuaGa(luaGa2);

                    thongBaoRepository.save(thongBao);
                    Map<String, String> exData = new HashMap<>();
                    exData.put("luaGaId", luaGa2.getId() + "");
                    firebaseMessagingService.SendNotificationToTopic(
                            thongBao.getTieu_de(), thongBao.getNoi_dung(),
                            luaGa2.getUserId().toString().replace("-", ""), "GROWTH", null, exData);
                }

                // =============================================================
                // 2. NHẮC NHỞ LỊCH TIÊM VACCINE
                // =============================================================
                if (vaccines != null && !vaccines.isEmpty()) {
                    for (DanhMucVaccine dm : vaccines) {
                        ThongBao thongBao = new ThongBao();
                        thongBao.setTieu_de("Thông báo lịch trình chăn nuôi!");
                        thongBao.setNoi_dung("Hôm nay là ngày tuổi thứ " + ngayTuoi + ", hãy thực hiện vaccine "
                                + dm.getTen_vaccine() + " cho đàn gà!");
                        thongBao.setDa_doc(false);
                        thongBao.setLoai_tb("vaccine");
                        thongBao.setThoi_gian_tao(LocalDateTime.now());
                        thongBao.setLuaGa(luaGa2);

                        thongBaoRepository.save(thongBao);
                        Map<String, String> exData = new HashMap<>();
                        exData.put("luaGaId", luaGa2.getId() + "");
                        firebaseMessagingService.SendNotificationToTopic(
                                thongBao.getTieu_de(),
                                thongBao.getNoi_dung(),
                                luaGa2.getUserId().toString().replace("-", ""),
                                "VACCINE",
                                null,
                                exData);
                    }
                }

                // =============================================================
                // 3. THÔNG BÁO ĐỊNH LƯỢNG THỨC ĂN HẰNG NGÀY (MỚI THÊM)
                // =============================================================
                try {
                    TieuChuanPhatTrien tieuChuan = tieuChuanPhatTrienRepository
                            .findTieuChuanGannhatTrongQuaKhu((int) ngayTuoi);
                    double dinhMucGram = (tieuChuan != null)
                            ? tieuChuan.getLuong_thuc_an_tieu_chuan()
                            : 0.0;
                    int soGa = luaGa2.getSo_luong_hien_tai();
                    double tongThucAnKg = tinhTongLuongThucAnKg(soGa, dinhMucGram);
                    String chuoiBao = quyDoiBaoNgan(tongThucAnKg);

                    ThongBao thongBaoFeed = new ThongBao();
                    thongBaoFeed.setTieu_de("Khẩu phần cám hôm nay 🌾");
                    thongBaoFeed.setNoi_dung("Lứa gà " + ngayTuoi + " ngày tuổi (" + soGa + " con): Cần cho ăn khoảng "
                            + tongThucAnKg + " kg cám (" + chuoiBao + "). Định mức: " + (int) dinhMucGram + "g/con.");
                    thongBaoFeed.setDa_doc(false);
                    thongBaoFeed.setLoai_tb("daily_feed");
                    thongBaoFeed.setThoi_gian_tao(LocalDateTime.now());
                    thongBaoFeed.setLuaGa(luaGa2);

                    thongBaoRepository.save(thongBaoFeed);
                    Map<String, String> exFeed = new HashMap<>();
                    firebaseMessagingService.SendNotificationToTopic(
                            thongBaoFeed.getTieu_de(),
                            thongBaoFeed.getNoi_dung(),
                            luaGa2.getUserId().toString().replace("-", ""),
                            "FEED",
                            null,
                            exFeed);

                } catch (Exception e) {
                    System.err.println(
                            "Lỗi tính định lượng thức ăn cho lứa gà " + luaGa2.getId() + ": " + e.getMessage());
                }

            }
        } catch (Exception e) {
            System.err.println(e.getMessage());
        }
    }

    private double tinhTongLuongThucAnKg(int soLuong, double dinhMucGram) {
        if (soLuong <= 0 || dinhMucGram <= 0)
            return 0.0;
        double tongKg = (soLuong * dinhMucGram) / 1000.0;
        return Math.round(tongKg * 10.0) / 10.0;
    }

    private String quyDoiBaoNgan(double kg) {
        if (kg <= 0)
            return "0 bao";
        double kgPerBao = 25.0;

        if (kg % kgPerBao == 0) {
            return (int) (kg / kgPerBao) + " bao";
        }

        int soBaoNguyen = (int) (kg / kgPerBao);
        double kgDu = Math.round((kg % kgPerBao) * 10.0) / 10.0;

        if (soBaoNguyen == 0) {
            return kgDu + " kg";
        }
        return soBaoNguyen + " bao + " + kgDu + " kg";
    }

    @Scheduled(cron = "0 30 0 * * ?")
    public void updateDailyChickenStandards() {
        try {
            int rowDeleted = camBienHomNayRepository.deleteOldSensorData();
            System.out.println("🧹 [HỆ THỐNG] Đã dọn dẹp hệ thống, xóa" + rowDeleted + " bản ghi cảm biến cũ.");
        } catch (Exception e) {
            System.err.println("Loi: " + e.getMessage());
        }

        List<LuaGa> activeluaGas = luaGaRepository.findByTrangThai("RAISING");
        for (LuaGa lg : activeluaGas) {
            int ngayTuoi = (int) ChronoUnit.DAYS.between(lg.getNgay_nhap(), LocalDate.now()) + 1;
            int lightStart;
            int lihgtEnd;
            if (ngayTuoi < 22) {
                lightStart = 2;
                lihgtEnd = 23;
            } else if (ngayTuoi < 57) {
                lightStart = 5;
                lihgtEnd = 23;
            } else {
                lightStart = 7;
                lihgtEnd = 21;
            }
            String topic = "chuong_ga/users/" + lg.getUserId() + "/controls";
            try {
                Map<String, Object> lightMap = new HashMap<>();
                lightMap.put("mode", "SET_LIGHT");
                lightMap.put("sender", "BE");
                lightMap.put("lightStartHour", lightStart);
                lightMap.put("lightEndHour", lihgtEnd);
                String lightMapPayload = objectMapper.writeValueAsString(lightMap);
                mqttConfig.publishLenhPhanCung(topic, lightMapPayload);
            } catch (Exception e) {
                System.err.println("Lỗi gửi lệnh mqtt: " + e.getMessage());
            }
        }
    }
}
