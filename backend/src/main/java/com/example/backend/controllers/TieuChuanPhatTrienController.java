package com.example.backend.controllers;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.entities.TieuChuanPhatTrien;
import com.example.backend.services.TieuChuanPhatTrienService;

@RestController
@RequestMapping("/api/TieuChuanPhatTrien")
public class TieuChuanPhatTrienController {
    @Autowired
    private TieuChuanPhatTrienService tieuChuanPhatTrienService;

    @GetMapping("/NgayTuoi/{ngayTuoi}")
    public TieuChuanPhatTrien gTieuChuanPhatTrienByNgayTuoi(@PathVariable int ngayTuoi){
        return tieuChuanPhatTrienService.findTieuChuanPhatTrienByNgayTuoi(ngayTuoi);
    }

    @GetMapping("/ThucAn/{ngayTuoi}")
    public ResponseEntity<?> getTongLuongThucAnTichLuyDenNgay(@PathVariable int ngayTuoi){
        int luongTA = tieuChuanPhatTrienService.getTongLuongThucAnTichLuyDenNgay(ngayTuoi);
        Map<String, Object> res= new HashMap<>();
        res.put("KhoiLuongTA", luongTA);
        return ResponseEntity.ok(res);
    }
}
