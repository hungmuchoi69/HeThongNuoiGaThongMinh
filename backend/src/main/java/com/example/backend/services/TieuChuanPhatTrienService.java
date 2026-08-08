package com.example.backend.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.backend.entities.TieuChuanPhatTrien;
import com.example.backend.repositories.TieuChuanPhatTrienRepository;

@Service
public class TieuChuanPhatTrienService {
    @Autowired
    private TieuChuanPhatTrienRepository tieuChuanPhatTrienRepository;

    public TieuChuanPhatTrien findTieuChuanPhatTrienByNgayTuoi(int ngayTuoi){
        return tieuChuanPhatTrienRepository.findTieuChuanGannhatTrongQuaKhu(ngayTuoi);
    }

    public int getTongLuongThucAnTichLuyDenNgay(int ngayTuoi){
        return tieuChuanPhatTrienRepository.getTongLuongThucAnTichLuyDenNgay(ngayTuoi);
    }
}
