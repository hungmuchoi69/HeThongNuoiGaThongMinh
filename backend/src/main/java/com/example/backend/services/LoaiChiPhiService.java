package com.example.backend.services;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.backend.entities.LoaiChiPhi;
import com.example.backend.repositories.LoaiChiPhiRepository;

@Service
public class LoaiChiPhiService {
    @Autowired
    private LoaiChiPhiRepository loaiChiPhiRepository;

    public List<LoaiChiPhi> getAllChiPhis(){
        return loaiChiPhiRepository.findAll();
    }
}
