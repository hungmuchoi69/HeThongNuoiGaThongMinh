package com.example.backend.services;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

import com.example.backend.config.MqttConfig;
import com.example.backend.entities.ThongBao;
import com.example.backend.repositories.ThongBaoRepository;

@Service
public class ThongBaoService {
    @Autowired
    private ThongBaoRepository thongBaoRepository;

    @Autowired
    @Lazy
    private MqttConfig mqttConfig;

    public List<ThongBao> getAllThongBao(int idLuaGa){
        return thongBaoRepository.geThongBaoByLuaga(idLuaGa);
    }

    public ThongBao createThongBao(ThongBao thongBao){
        return thongBaoRepository.save(thongBao);
    }

    public ThongBao updateThongBao(int id){
        Optional<ThongBao> tb =thongBaoRepository.findById(id);
        if(tb.isPresent()){
            ThongBao existingThongBao = tb.get();
            existingThongBao.setDa_doc(true);
            return thongBaoRepository.save(existingThongBao);
        }
        return null;
    }

    public int getThongBaoChuaDoc(int id){
        return thongBaoRepository.getThongBaoChuaDoc(id);
    }

    public boolean docMotThongBao(int idThongBao, UUID userId, int idLuaGa){
        int row= thongBaoRepository.markAsRead(idThongBao);
        if(row>0){
            mqttConfig.PublishUnreadCound(userId, idLuaGa);
            return true;
        }
        return false;
    }

    public boolean docTatCaThongBao(int idLuaGa, UUID userId){
        int row=thongBaoRepository.markAllRead(idLuaGa);
        if(row>0){
            mqttConfig.PublishUnreadCound(userId, idLuaGa);
            return true;
        }
        return false;
    }
}
