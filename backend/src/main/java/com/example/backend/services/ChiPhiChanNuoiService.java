package com.example.backend.services;

import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.backend.entities.ChiPhiChanNuoi;
import com.example.backend.repositories.ChiPhiChanNuoiRepository;

@Service
public class ChiPhiChanNuoiService {
    @Autowired
    private ChiPhiChanNuoiRepository chiPhiChanNuoiRepository;

    public List<ChiPhiChanNuoi> getAllChiPhiChanNuois(int idLuaGa){
        return chiPhiChanNuoiRepository.getChiPhiByLuaGa(idLuaGa);
    }

    public ChiPhiChanNuoi createChiPhiChanNuoi(ChiPhiChanNuoi chiPhiChanNuoi){
        return chiPhiChanNuoiRepository.save(chiPhiChanNuoi);
    }

    public ChiPhiChanNuoi updateChiPhiChanNuoi(int id, ChiPhiChanNuoi chiphiDeatail){
        Optional<ChiPhiChanNuoi> chiphi = chiPhiChanNuoiRepository.findById(id);
        if(chiphi.isPresent()){
            ChiPhiChanNuoi existingChiPhiChanNuoi=chiphi.get();
            existingChiPhiChanNuoi.setLoaiChiPhi(chiphiDeatail.getLoaiChiPhi());
            existingChiPhiChanNuoi.setNgay_chi_tieu(chiphiDeatail.getNgay_chi_tieu());
            existingChiPhiChanNuoi.setSo_tien(chiphiDeatail.getSo_tien());
            existingChiPhiChanNuoi.setGhi_chu(chiphiDeatail.getGhi_chu());
            return chiPhiChanNuoiRepository.save(existingChiPhiChanNuoi);
        }
        return null;
    }
}
